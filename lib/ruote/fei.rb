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


module Ruote

  class FlowExpressionId

    CHILD_SEP = '_'
    SUBP_SEP = '_'

    attr_accessor :engine_id
    attr_accessor :wfid
    attr_accessor :expid

    alias :pid :wfid

    def to_s

      "#{@engine_id}|#{@wfid}|#{@expid}"
    end

    def hash

      to_s.hash
    end

    def == (other)

      return false unless other.is_a?(FlowExpressionId)

      (hash == other.hash)
    end

    alias eql? ==

    def child_id

      @expid.split(CHILD_SEP).last.to_i
    end

    def new_child_fei (child_index)

      cfei = self.dup
      cfei.expid = [ @expid, CHILD_SEP, child_index ].join

      cfei
    end

    def parent_wfid

      @wfid.split(SUBP_SEP).first
    end

    def sub_wfid

      ss = @wfid.split(SUBP_SEP)
      ss.size > 1 ? ss.last : nil
    end

    def to_h

      %w[ engine_id wfid expid ].inject({ 'class' => self.class.to_s }) { |h, k|
        h[k] = instance_variable_get("@#{k}")
        h
      }
    end

    def self.from_h (h)

      %w[ engine_id wfid expid ].inject(FlowExpressionId.new) { |fei, k|
        fei.instance_variable_set("@#{k}", h[k.to_sym] || h[k])
        fei
      }
    end

    # Returns a complete (deep) copy of this FlowExpressionId instance.
    #
    def dup

      Ruote.fulldup(self)
    end

    # Helper method : returns the depth of this expression in its process
    # instance. The root expression has a depth of 0.
    #
    def depth

      (@expid.split(CHILD_SEP).size - 1)
    end
  end
end

