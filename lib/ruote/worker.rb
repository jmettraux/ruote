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

  VERSION = '2.1.0'

  class Worker

    EXP_ACTIONS = %w[ reply cancel ]
      # 'apply' is comprised in 'launch'

    PROC_ACTIONS = %w[ cancel_process kill_process ]

    attr_reader :storage
    attr_reader :context

    def initialize (storage)

      @storage = storage

      @subscribers = []
      @context = Ruote::WorkerContext.new(self)
    end

    def run

      last_time = Time.at(0.0).utc # 1970...

      loop do

        now = Time.now.utc
        delta = now - last_time

        if delta >= 1.0
          #
          # at most once per second

          last_time = now

          # at schedules

          @storage.get_ats(delta, now).each { |sche| trigger_at(sche) }

          # cron schedules

          @storage.get_crons(delta, now).each { |sche| trigger_cron(sche) }
        end

        # tasks

        tasks = @storage.get_many('tasks')

        tasks.sort { |a, b|
          a['put_at'] <=> b['put_at']
        }.each { |task|
          process(task)
        }

        sleep(0.100) if tasks.size == 0
      end
    end

    def subscribe (type, actions, subscriber)

      @subscribers << [ type, actions, subscriber ]
    end

    protected

    def trigger_at (schedule)

      task = schedule['task']

      type = schedule['type']

      if type == 'ats'

        return if @storage.delete(schedule)

        @storage.put_task(task.delete('action'), task)

      else

        raise "implement me !"
      end
    end

    def trigger_cron (schedule)
    end

    def process (task)

      return if cannot_handle(task)

      return if @storage.delete(task)
        #
        # NOTE : if the delete fails, it means there is another worker...

      fexp = nil

      begin

        action = task['action']

        action = 'reply' if action == 'receive'

        if task['tree']

          launch(task)

        elsif EXP_ACTIONS.include?(action)

          fexp = Ruote::Exp::FlowExpression.fetch(@context, task['fei'])

          fexp.send("do_#{action}", task) if fexp

        elsif action == 'dispatch'

          dispatch(task)

        elsif PROC_ACTIONS.include?(action)

          self.send(action, task)

        #else
          # task got delete, might still be interesting for a subscriber
        end

        notify(task)

      rescue Exception => e

        #puts "\n== worker intercepted error =="
        #puts
        #p e
        #e.backtrace[0, 10].each { |l| puts l }
        #puts "..."
        #puts
        #puts "-- task --"
        #task.keys.sort.each { |k|
        #  puts "    #{k.inspect} =>\n#{task[k].inspect}"
        #}
        #puts "-- . --"
        #puts

        # emit 'task'

        wfid = task['wfid'] || (task['fei']['wfid'] rescue nil)

        @storage.put_task(
          'error_intercepted',
          'message' => e.inspect,
          'wfid' => wfid,
          'task' => task)

        # fill error in the error journal

        fei = task['fei'] || (fexp.h.fei rescue nil)

        @storage.put(
          'type' => 'errors',
          '_id' => Ruote::FlowExpressionId.to_storage_id(fei),
          'message' => e.inspect,
          'trace' => e.backtrace.join("\n"),
          'task' => task
        ) if fei
      end
    end

    def notify (event)

      @subscribers.each do |type, actions, subscriber|

        next unless type == :all || event['type'] == type
        next unless actions == :all || actions.include?(event['action'])

        subscriber.notify(event)
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

      # task['wfid'] only : it's a launch
      # task['fei'] : it's a sub launch (a supplant ?)

      exp_hash = {
        'fei' => task['fei'] || {
          'engine_id' => @context['engine_id'] || 'engine',
          'wfid' => task['wfid'],
          'expid' => '0' },
        'parent_id' => task['parent_id'],
        'original_tree' => tree,
        'variables' => variables,
        'applied_workitem' => task['workitem'],
        'forgotten' => task['forgotten']
      }

      if not exp_class

        exp_class, tree = lookup_subprocess_or_participant(exp_hash)

      elsif task['action'] == 'launch' && exp_class == Ruote::Exp::DefineExpression
        def_name, tree = Ruote::Exp::DefineExpression.reorganize(tree)
        variables[def_name] = [ '0', tree ] if def_name
        exp_class = Ruote::Exp::SequenceExpression
      end

      raise_unknown_expression_error(exp_hash) unless exp_class

      exp = exp_class.new(@context, exp_hash.merge!('original_tree' => tree))
      exp.persist
      exp.do_apply
    end

    def raise_unknown_expression_error (exp_hash)

      exp_hash['state'] = 'failed'
      exp_hash['has_error'] = true

      Ruote::Exp::RawExpression.new(@context, exp_hash).persist
        # undigested expression is stored

      raise "unknown expression '#{exp_hash['original_tree'].first}'"
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

    def cancel_process (task)

      root = @storage.find_root_expression(task['wfid'])

      return unless root

      @storage.put_task(
        'cancel',
        'fei' => root['fei'],
        'wfid' => task['wfid']) # indicates this was triggered by a cancel_process
    end

    def kill_process (task)

      raise "implement me !"
    end
  end
end

