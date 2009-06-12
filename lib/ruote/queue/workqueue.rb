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


require 'thread'
require 'ruote/engine/context'


module Ruote

  class BlockSubscriber
    def initialize (block)
      @block = block
    end
    def receive (eclass, emessage, args)
      @block.call(eclass, emessage, args)
    end
  end

  class WorkQueue

    include EngineContext

    def initialize

      @subscribers = { :all => [] }
    end

    def add_subscriber (eclass, subscriber)

      (@subscribers[eclass] ||= []) << subscriber

      subscriber
    end

    def subscribe (eclass, &block)

      add_subscriber(eclass, BlockSubscriber.new(block))
    end

    def remove_subscriber (subscriber)

      @subscribers.values.each { |v| v.delete(subscriber) }
    end

    # Emits event for immediate processing
    #
    def emit! (eclass, emsg, eargs)

      process([ eclass, emsg, eargs ])
    end

    protected

    def process (event)

      begin

        eclass, emsg, eargs = event

        #
        # using #send, so that protected #receive are OK

        os = @subscribers[eclass]
        os.each { |o| o.send(:receive, eclass, emsg, eargs) } if os

        @subscribers[:all].each { |o| o.send(:receive, eclass, emsg, eargs) }

      rescue Exception => e

        # TODO : rescue for each subscriber, don't care if 1+ fails,
        #        send to others anyway

        p [ :wqueue_process, e.class, e ]
        puts e.backtrace
      end
    end
  end

  class ThreadWorkQueue < WorkQueue

    def initialize

      super()

      @queue = Queue.new

      @thread = Thread.new do
        loop { process(@queue.pop) }
      end
    end

    # Emits event for later processing
    #
    def emit (eclass, emsg, eargs)

      @queue.push([ eclass, emsg, eargs ])
    end
  end

  #--
  # Not very interesting
  #
  #class FiberWorkQueue < WorkQueue
  #  def initialize
  #    @queue = Queue.new
  #    @unit = nil
  #    @thread = Thread.new do
  #      unit = nil
  #      fiber = Fiber.new do
  #        loop do
  #          process(unit)
  #          Fiber.yield
  #        end
  #      end
  #      loop do
  #        unit = @queue.pop
  #        fiber.resume
  #      end
  #    end
  #  end
  #  def push (target, method, *args)
  #    @queue.push([ target, method, args ])
  #  end
  #end
  #++

  # Works well when IO is involved (this means, almost always)
  #
  class EmWorkQueue < WorkQueue

    def emit (eclass, emsg, eargs)

      EM.next_tick { process([ eclass, emsg, eargs ]) }
        # that's all there is to it
    end
  end

end

