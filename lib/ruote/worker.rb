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

      return if @storage.delete(task)
        #
        # NOTE : if the delete fails, it means there is another worker...

      begin

        action = task['action']
        action = 'reply' if action == 'received'

        if task['tree']

          launch(task)

        elsif EXP_ACTIONS.include?(action)

          Ruote::Exp::FlowExpression.get_expression(@context, task['fei']).send(
            "do_#{action}", task['workitem'])

        #elsif action == 'dispatch'
        #  dispatch(task)

        #else
          # task got delete, might still be interesting for a subscriber
        end

        notify(task)

      rescue Exception => e

        #puts "\n== worker intercepted error =="
        #p e
        #e.backtrace.each { |l| puts l }
        #puts

        # emit 'task'

        wfid = task['wfid'] || task['fei']['wfid']

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

    #def dispatch (task)
    #  # does it know this participant ?
    #  pname = task['participant_name']
    #  participant = @context.plist.lookup_participant(pname)
    #  # timeout ?
    #  # REALLY split apply from dispatch ?
    #  participant.consume(task)
    #end

    # Works for both the 'launch' and the 'apply' tasks.
    #
    def launch (task)

      tree = task['tree']

      workitem = task['workitem']
      variables = task['variables']

      fei = task['fei'] || {
        'engine_id' => @context['engine_id'] || 'engine',
        'wfid' => task['wfid'],
        'expid' => '0'
      }

      workitem['fei'] = fei

      exp_name = tree.first
      exp_class = @context.expmap.expression_class(exp_name)

      if task['action'] == 'launch' && exp_class == Ruote::Exp::DefineExpression
        def_name, tree = Ruote::Exp::DefineExpression.reorganize(tree)
        variables[def_name] = [ '0', tree ] if def_name
        exp_class = Ruote::Exp::SequenceExpression
      end

      exp = exp_class.new(
        @context,
        'fei' => fei,
        'parent_id' => task['parent_id'],
        'original_tree' => tree.dup,
        'variables' => variables,
        'applied_workitem' => workitem
      )

      exp.persist
      exp.do_apply

      #fei
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

