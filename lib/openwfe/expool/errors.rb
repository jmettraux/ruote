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


module OpenWFE

  #
  # This error is raised when an expression belonging to a paused
  # process is applied or replied to.
  #
  class PausedError < RuntimeError

    attr_reader :wfid

    def initialize (wfid)

      super "process '#{wfid}' is paused"
      @wfid = wfid
    end

    #
    # Returns a hash for this PausedError instance.
    # (simply returns the hash of the paused process' wfid).
    #
    def hash

      @wfid.hash
    end

    #
    # Returns true if the other is a PausedError issued for the
    # same process instance (wfid).
    #
    def == (other)

      return false unless other.is_a?(PausedError)

      (@wfid == other.wfid)
    end
  end

  #
  # This is the error used by the 'error' expression (forcing an error...)
  #
  class ForcedError < RuntimeError
  end
end

