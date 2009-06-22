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


require 'set'
require 'ruote/engine/context'
require 'ruote/queue/subscriber'


module Ruote

  #
  # Tracking events for the 'listen' expression.
  #
  # Could be adapted later for tracking other events.
  #
  class Tracker

    include EngineContext
    include Subscriber

    def initialize

      @reloaded = false
      @listeners = Set.new
      @mutex = Mutex.new
    end

    def context= (c)

      @context = c
      subscribe(:workitems)
    end

    def register (fei)

      @listeners << fei
    end

    def unregister (fei)

      @listeners.delete(fei)
    end

    protected

    def receive (eclass, emsg, eargs)

      reload unless @reloaded

      @listeners.to_a.each do |fei|

        fexp = expstorage[fei]

        if fexp

          wqueue.emit(
            :expressions, :reply, :fei => fei, :workitem => eargs[:workitem]
          ) if fexp.match_event?(eclass, emsg, eargs)

        else

          @listeners.delete(fei)
        end
      end
    end

    # Reload listeners from expstorage
    #
    def reload

      exps = expstorage.find_expressions(:class => Ruote::ListenExpression)
      exps.each { |e| @listeners << e.fei }

      @reloaded = true
    end
  end
end

