#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'ruote/fei'


module Ruote

  class Worker

    EXP_ACTIONS = %w[ apply reply cancel ]

    attr_reader :storage
    attr_reader :context

    def initialize (storage)

      @storage = storage
      @last_second = -1

      @subscribers = []
      @context = Ruote::WorkerContext.new(self)
    end

    def run

      loop do

        t = Time.now

        if t.sec != @last_second

          @last_second = t.sec

          # at schedules
          @storage.get_many('ats', //).each { |sche| trigger(sche) }

          # cron schedules
          @storage.get_many('crons', //).each { |sche| trigger(sche) }
        end

        # tasks
        tasks = @storage.get_many('tasks')
        tasks.each { |task| process(task) }

        sleep(0.100) if tasks.size == 0
      end
    end

    def subscribe (type, actions, subscriber)

      @subscribers << [ type, actions, subscriber ]
    end

    protected

    def trigger (schedule)

      raise "implement me !"
      #notify(schedule) # orly ?
    end

    def process (task)

      return if cannot_handle(task)

      return if @storage.delete(task)
        #
        # NOTE : if the delete fails, it means there is another worker...

      begin

        action = task['action']

        action = 'reply' if action == 'receive'

        if task['tree']

          launch(task)

        elsif EXP_ACTIONS.include?(action)

          Ruote::Exp::FlowExpression.fetch(
            @context, task['fei']
          ).send("do_#{action}", task['workitem'])

        elsif action == 'dispatch'

          dispatch(task)

        #else
          # task got delete, might still be interesting for a subscriber
        end

        notify(task)

      rescue Exception => e

        puts "\n== worker intercepted error =="
        p e
        e.backtrace.each { |l| puts l }
        puts

        # emit 'task'

        wfid = task['wfid'] || (task['fei']['wfid'] rescue nil)

        @storage.put_task(
          'error_intercepted',
          'error' => e.inspect,
          'wfid' => wfid,
          'task' => task)

        # fill error in the error journal

        @storage.put(
          'type' => 'errors',
          '_id' => Ruote::FlowExpressionId.to_storage_id(task['fei']),
          'error' => e.inspect,
          'trace' => e.backtrace.join("\n"))
      end
    end

    def cannot_handle (task)

      return false if task['action'] != 'dispatch'

      @context.engine.nil? && task['for_engine_worker?']
    end

    def dispatch (task)

      pname = task['participant_name']

      participant = @context.plist.lookup(pname)

      participant.consume(Ruote::Workitem.new(task['workitem']))
    end

    # Works for both the 'launch' and the 'apply' tasks.
    #
    def launch (task)

      tree = task['tree']
      variables = task['variables']

      exp_class = @context.expmap.expression_class(tree.first)

      exp_hash = {
        'fei' => task['fei'] || {
          'engine_id' => @context['engine_id'] || 'engine',
          'wfid' => task['wfid'],
          'expid' => '0' },
        'parent_id' => task['parent_id'],
        'original_tree' => tree,
        'variables' => variables,
        'applied_workitem' => task['workitem']
      }

      if not exp_class

        exp_class, tree = lookup_subprocess_or_participant(exp_hash)

      elsif task['action'] == 'launch' && exp_class == Ruote::Exp::DefineExpression
        def_name, tree = Ruote::Exp::DefineExpression.reorganize(tree)
        variables[def_name] = [ '0', tree ] if def_name
        exp_class = Ruote::Exp::SequenceExpression
      end

      raise "unknown expression '#{tree.first}'" unless exp_class

      exp = exp_class.new(@context, exp_hash)
      exp.persist
      exp.do_apply
    end

    def lookup_subprocess_or_participant (exp_hash)

      tree = exp_hash['original_tree']

      key, value = Ruote::Exp::FlowExpression.new(
        @context, exp_hash.merge('name' => 'temporary')
      ).iterative_var_lookup(tree[0])

      sub = value
      part = @context.plist.lookup_info(key)

      sub = key if (not sub) && (not part) && Ruote.is_uri?(key)
        # for when a variable points to the URI of a[n external] subprocess

      if sub or part

        tree[1]['ref'] = key
        tree[1]['original_ref'] = tree[0] if key != tree[0]

        tree[0] = sub ? 'subprocess' : 'participant'

        [ sub ?
            Ruote::Exp::SubprocessExpression :
            Ruote::Exp::ParticipantExpression,
          tree ]
      else

        [ nil, tree ]
      end
    end

    def notify (event)

      @subscribers.each do |type, actions, subscriber|

        next unless type == :all || event['type'] == type
        next unless actions == :all || actions.include?(event['action'])

        subscriber.notify(event)
      end
    end
  end
end

