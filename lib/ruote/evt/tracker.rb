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


require 'ruote/engine/context'
require 'ruote/queue/subscriber'


module Ruote

  #
  # Used by the Tracker to keep decorate events with useful methods.
  #
  class Event

    def initialize (eclass, emsg, eargs)

      @class, @msg, @args = eclass, emsg, eargs
    end

    def match? (pclass, pmsg, pargs)

      return false if pclass && pclass != @class
      return false if pmsg && pmsg != @msg

      return true unless pargs

      pargs.each { |k, v| return false unless @args[k].match(v) }

      true
    end

    def workitem

      @args[:workitem]
    end
  end

  #
  # Tracking events for the 'listen' expression.
  #
  class Tracker

    include EngineContext
    include Subscriber

    def initialize

      @events = []
      @listeners = []
      @mutex = Mutex.new
    end

    def context= (c)

      @context = c
      subscribe(:workitems)
    end

    def register (fei, eclass, emsg, eargs)

      @listeners << [ fei, [ eclass, emsg, eargs ] ]
    end

    def unregister (fei)

      @listeners.delete_if { |l| l.first == fei }
    end

    def step

      evts = latest_events

      @listeners.each do |fei, pattern| # no listeners, no loop
        evts.each do |evt|
          wqueue.emit(
            :expressions, :reply, :fei => fei, :workitem => evt.workitem
          ) if evt.match?(*pattern)
        end
      end
    end

    protected

    def receive (eclass, emsg, eargs)

      @mutex.synchronize do
        @events << Event.new(eclass, emsg, eargs)
      end
    end

    def latest_events

      @mutex.synchronize do
        r = @events
        @events = []
        r
      end
    end
  end
end

