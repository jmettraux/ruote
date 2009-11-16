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

#require 'ruote/context'


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
          @storage.get_at_schedules(t).each { |sche| trigger(sche) }

          # cron schedules
          @storage.get_cron_schedules(t).each { |sche| trigger(sche) }
        end

        # tasks
        tasks = @storage.get_tasks
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

      return unless @storage.delete_task(task)

      begin

        action = task['action']

        if action == 'launch'
          launch(task)
        elsif EXP_ACTIONS.include?(action)
          get_expression(task).send("do_#{action}", self, task['workitem'])
        else
          # ???
        end

        notify(task)

      rescue Exception => e

        # TODO : log error ?
        p e
      end
    end

    def launch (task)

      puts "=== launch ==="
      p task
    end

    def get_expression (task)

      @storage.get_expression(task['fei'])
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

