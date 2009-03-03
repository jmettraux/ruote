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


module OpenWFE

  #
  # This mixin gathers all the logic for a threaded expression storage,
  # one that doesn't immediately stores workitems (removes overriding
  # operations).
  # Using this threaded storage brings a very important perf benefit.
  #
  module ThreadedStorageMixin

    #
    # Will take care of stopping the 'queue processing' thread.
    #
    def stop

      @stopped = true
      @queue.push :stop
    end

    #
    # makes sure that the queue isn't actually preparing a batch
    # before returning a result.
    #
    def find_expressions (options={})

      Thread.pass

      @mutex.synchronize do
        super(options)
      end
    end

    protected

      #
      # starts the thread that does the actual persistence.
      #
      def start_queue

        @mutex = Mutex.new
        @queue = Queue.new

        Thread.new do

          loop do

            events = [ @queue.pop ]

            @mutex.synchronize do

              14.times { Thread.pass }
                #
                # gather some steam :
                # let jobs accumulate

              @queue.size.times do
                events << @queue.pop
              end

              process_events events
            end

            break if events.include?(:stop)
          end
        end
      end

      #
      # queues an event for later (well within a second) persistence
      #
      def queue (event, fei, fexp=nil)

        if @stopped
          process_event event, fei, fexp
        else
          @queue.push [ event, fei, fexp ]
        end
      end

      def process_events (events)

        ldebug { "process_events() #{events.size} events" }

        # reducing the operation count

        events = events.inject({}) do |r, event|
          r[event[1]] = event if event != :stop
          r
        end

        ldebug { "process_events() #{events.size} events remaining" }

        # perform the remaining operations

        events.each_value do |event, fei, fexp|

          process_event event, fei, fexp
        end
      end

      def process_event (event, fei, fexp)

        begin
          if event == :update
            self[fei] = fexp
          else
            self.delete(fei)
          end
        rescue Exception => e
          lwarn do
            "process_event() ':#{event}' exception\n" +
            OpenWFE::exception_to_s(e)
          end
        end
      end

      #
      # Adds the queue() method as an observer to the update and remove
      # events of the expression pool.
      # :update and :remove mean changes to expressions in the persistence
      # that's why they are observed.
      #
      def observe_expool

        get_expression_pool.add_observer(:update) do |event, fei, fe|
          #ldebug { ":update  for #{fei.to_debug_s}" }
          queue(event, fei, fe)
        end
        get_expression_pool.add_observer(:remove) do |event, fei|
          #ldebug { ":remove  for #{fei.to_debug_s}" }
          queue(event, fei)
        end
      end
  end
end
