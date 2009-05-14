#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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

  class BlockObserver
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

      @observers = { :all => [] }
    end

    def add_observer (eclass, observer)

      (@observers[eclass] ||= []) << observer
      observer
    end

    def observe (eclass, &block)

      add_observer(BlockObserver.new(block), eclass)
    end

    def remove_observer (observer)

      @observers.values.each { |v| v.delete(observer) }
    end

    protected

    def process (event)

      begin

        eclass, emsg, eargs = event

        os = @observers[eclass]
        os.each { |o| o.receive(eclass, emsg, eargs) } if os

        @observers[:all].each { |o| o.receive(eclass, emsg, eargs) }

      rescue Exception => e
        p [ e.class, e ]
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

  # Works well when IO is involved (this mean, almost always)
  #
  class EmWorkQueue < WorkQueue

    def emit (eclass, emsg, eargs)

      EM.next_tick { process([ eclass, emsg, eargs ]) }
        # that's all there is to it
    end
  end

end

