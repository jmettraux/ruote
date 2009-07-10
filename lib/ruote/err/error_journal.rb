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
  # Encapsulating all the information about an error in a process instance.
  #
  class ProcessError

    def initialize (h)
      @h = h
    end

    def when
      @h[:when]
    end

    # The 'internal' bus event
    #
    def msg
      @h[:message]
    end

    def error
      @h[:error]
    end

    def message
      error.to_s
    end

    def fei
      msg.last[:fei]
    end

    def wfid
      fei.wfid
    end

    def tree
      msg.last[:tree]
    end

    # A shortcut for modifying the tree of an expression when it has had
    # an error upon being applied.
    #
    def tree= (t)

      raise "no tree in error, can't override" unless tree
      msg.last[:tree] = t
    end
  end

  #
  # Keeping track of the errors plaguing processes.
  #
  class ErrorJournal

    include EngineContext
    include Subscriber

    def initialize

      @errors = {}
    end

    def context= (c)

      @context = c
      subscribe(:errors)
    end

    # Returns the list of errors for a given process instance
    #
    def process_errors (wfid)

      (@errors[wfid] || {}).values.collect { |e| ProcessError.new(e) }
    end

    # Returns all the current errors
    #
    # { wfid => [ ProcessError instances ] }
    #
    def errors

      @errors.inject({}) do |h, (wfid, errs)|
        h[wfid] = errs.values.collect { |e| ProcessError.new(e) }
        h
      end
    end

    protected

    def receive (eclass, emsg, eargs)

      info = eargs[:message].last

      fei = info[:fei] || (info[:expression] || info[:workitem]).fei
      wfid = info[:wfid]

      eargs[:when] = Time.now

      (@errors[wfid || fei.parent_wfid] ||= {})[fei] = eargs

      # could a lonely wfid be a sub wfid ? ...
    end
  end
end

