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

require 'ruote/queue/subscriber'


module Ruote

  #
  # The #wait_for method used in some command line examples.
  # Not relevant for a classical ruote server setting.
  #
  class Engine

    #
    # A helper class for the #wait_for method.
    #
    class Waiting

      include EngineContext
      include Subscriber

      attr_reader :outcome

      def initialize (context, wfid)
        @context = context
        @wfid = wfid
        @thread = Thread.current
        subscribe(:all)
        Thread.stop
      end

      def receive (eclass, emsg, eargs)

        return unless eargs[:wfid] == @wfid

        if eclass == :errors || (eclass == :processes && emsg == :terminated)
          unsubscribe
          @outcome = [ eclass, emsg, eargs ]
          @thread.wakeup
        end
      end
    end

    # Makes the current Thread wait until process wfid terminates.
    # This method is meant for small engine demonstrations. In a real install
    # you usually have no reason to wait for a particular process to terminate.
    #
    def wait_for (wfid)

      Waiting.new(@context, wfid).outcome
    end
  end
end

