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
    SUBP_REGEX = /^(.+)\_(\d+)$/

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

      self.class.wfid_split(@wfid)[0]
    end

    def sub_wfid

      self.class.wfid_split(@wfid)[1]
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

    # Returns a brief string sub_wfid/expid. Used in some functional tests.
    #
    #   fei.brief => '/0'
    #
    # indicates the expression at the root of a main (not a subprocess)
    # instance.
    #
    def brief

      "#{sub_wfid}/#{expid}"
    end

    def diff (fei)

      return fei \
        if fei.engine_id != @engine_id
      return fei \
        if fei.parent_wfid != self.parent_wfid

      return fei.child_id.to_i \
        if fei.wfid == @wfid && fei.parent_expid == @expid
      return fei.sub_wfid \
        if fei.expid == '0'

      fei
    end

    def undiff (i)

      return i if i.is_a?(FlowExpressionId)

      fei = self.dup

      if i.is_a?(String)
        fei.wfid = "#{fei.parent_wfid}#{CHILD_SEP}#{i}"
      else # i is an number
        fei.expid = "#{fei.expid}#{CHILD_SEP}#{i}"
      end

      fei
    end

    def self.parent_wfid (wfid)

      wfid_split(wfid)[0]
    end

    def self.sub_wfid (wfid)

      wfid_split(wfid)[1]
    end

    # Turns a string back into a FlowExpressionId.
    #
    #   s = fei.to_s
    #   fei1 = Ruote::FlowExpressionId.from_s(s)
    #   p fei1 == fei # => true
    #
    def self.from_s (s)

      ss = s.split('|')

      raise(ArgumentError.new(
        "string '#{s}' can't be turned back into a " +
        "Ruote::FlowExpressionId instance"
      )) if ss.length != 3

      fei = FlowExpressionId.new
      fei.engine_id = ss[0]
      fei.wfid = ss[1]
      fei.expid = ss[2]

      fei
    end

    protected

    # Splits the wfid into [ parent_wfid, subprocess_id ]
    #
    def self.wfid_split (wfid)

      if m = SUBP_REGEX.match(wfid)
        [ m[1], m[2] ]
      else
        [ wfid ]
      end
    end

    def parent_expid

      @expid.split(CHILD_SEP)[0..-2].join(CHILD_SEP)
    end
  end
end

