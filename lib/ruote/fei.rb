#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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


require 'ruote/util/misc'
require 'ruote/util/hashdot'


module Ruote

  class FlowExpressionId

    CHILD_SEP = '_'

    attr_reader :h

    def initialize (h)

      @h = h
      class << h; include Ruote::HashDot; end
    end

    def expid
      @h['expid']
    end

    def wfid
      @h['wfid']
    end

    def sub_wfid
      @h['sub_wfid']
    end

    def to_storage_id

      "#{@h['expid']}|#{@h['sub_wfid']}|#{@h['wfid']}"
    end

    def self.to_storage_id (hfei)

      "#{hfei['expid']}|#{hfei['sub_wfid']}|#{hfei['wfid']}"
    end

    # Returns the last number in the expid. For instance, if the expid is
    # '0_5_7', the child_id will be '7'.
    #
    def child_id

      h.expid.split(CHILD_SEP).last.to_i
    end

    def hash

      to_storage_id.hash
    end

    def == (other)

      return false unless other.is_a?(Ruote::FlowExpressionId)

      (hash == other.hash)
    end

    alias eql? ==
  end
end

