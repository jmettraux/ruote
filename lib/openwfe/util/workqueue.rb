#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'thread'
require 'openwfe/utils'


module OpenWFE

  class WorkQueue < Service

    include OwfeServiceLocator

    #
    # Inits the WorkQueue
    #
    def service_init (service_name, application_context)

      super

      @queue = Queue.new
      @stopped = false

      #thread_name = "#{service_name} (engine #{get_engine.object_id})"
      #OpenWFE::call_in_thread(thread_name, self) do
      #  loop do
      #    work = @queue.pop
      #    break if work == :stop
      #    target, method_name, args = work
      #    target.send(method_name, *args)
      #  end
      #end

      # the workqueue warns and immediately resumes in case of error.

      t = Thread.new do
        loop do
          begin
            work = @queue.pop
            break if work == :stop
            target, method_name, args = work
            target.send(method_name, *args)
          rescue Exception => e
            lwarn {
              "#{caller_name} caught an exception\n#{OpenWFE.exception_to_s(e)}"
            }
          end
        end
      end
      t[:name] = "#{service_name} (engine #{get_engine.object_id})"
    end

    #
    # Returns true if there is or there just was activity for the
    # work queue.
    #
    def busy?

      @queue.size > 0
    end

    #
    # Returns the current count of jobs on the workqueue
    #
    def size

      @queue.size
    end

    #
    # Stops the workqueue.
    #
    def stop

      @stopped = true
      @queue.push(:stop)
    end

    #
    # the method called by the mixer to actually queue the work.
    #
    def push (target, method_name, *args)

      #fei = args.find { |e| e.respond_to?(:fei) }
      #fei = fei.fei.to_s if fei
      #p [ :push, method_name, args.find { |e| e.is_a?(Symbol) }, fei ]

      if @stopped

        target.send(method_name, *args)
          #
          # degraded mode : as if there were no workqueue
      else

        @queue.push [ target, method_name, args ]
          #
          # work will be done later (millisec order)
          # by the work thread
      end
    end
  end
end

