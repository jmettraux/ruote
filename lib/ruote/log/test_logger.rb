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


require 'ruote/log/logger'


module Ruote

  # Logs everything that occurs in the workqueue in an array.
  #
  # DO NOT use this in production. It's testing only.
  #
  class TestLogger < Logger

    attr_reader :log

    def initialize

      @log = []
      @not_seen = []
    end

    # Some kind of busy waiting... (had bad results with thread.wakeup)
    #
    def wait_for (patterns, count=100)

      patterns = Array(patterns)

      for i in 0..count
        sleep 0.001
        while ev = @not_seen.pop
          patterns.each do |eclass, emsg, eargs|
            if match?(ev, eclass, emsg, eargs || {})
              sleep 0.050
              return
            end
          end
        end
        #print " #{i}"
      end
    end

    protected

    def receive (eclass, emsg, eargs)

      data = summarize(eclass, emsg, eargs)

      @log << data
      @not_seen << data

      p(data) if context[:noisy]
    end

    def match? (ev, eclass, emsg, eargs)

      ec, em, ea = ev

      return false if eclass && ec != eclass
      return false if emsg && em != emsg

      eargs.each { |k, v| return false if ea[k] != v }

      true
    end
  end
end

