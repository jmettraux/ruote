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


require 'ruote/engine/context'
require 'ruote/queue/subscriber'


module Ruote

  # Plain logger (outputs to stdout)
  #
  class Logger

    include EngineContext
    include Subscriber

    def context= (c)

      @context = c
      subscribe(:all)
    end

    protected

    def receive (eclass, emsg, eargs)

      p [ :ruote, eclass, emsg, summarize_args(eclass, emsg, eargs) ]
    end

    def summarize_args (eclass, emsg, eargs)

      if eargs.is_a?(Array)
        [ eargs[0], eargs[1], summarize_args(eargs[0], eargs[1], eargs[2]) ]
      elsif fei = eargs[:fei]
        fei.to_s
      elsif wfid = eargs[:wfid]
        wfid
      elsif exp = eargs[:expression]
        exp.fei.to_s
      else
        eargs.inject({}) { |h, (k, v)| h[k] = value_to_s(v); h }
      end
    end

    def value_to_s (v)
      case v
      when String then v
      when Symbol then v
      when Regexp then v
      else v.class
      end
    end
  end
end

