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


module Ruote

  module StorageBase

    # Receiving :expressions messages
    #
    def receive (eclass, emsg, eargs)

      case emsg
      when :update
        exp = eargs[:expression]
        self[exp.fei] = exp
      when :delete
        self.delete(eargs[:fei])
      end
    end

    protected

    # Observing the workqueue for :expressions messages
    #
    def observe_workqueue

      wqueue.add_observer(:expressions, self)
    end

    def fei_match? (fei, query)
      # TODO : if necessary ?
    end

    def exp_match? (exp, query)

      wfid = query[:wfid]

      (exp.fei.wfid == wfid)
    end
  end
end

