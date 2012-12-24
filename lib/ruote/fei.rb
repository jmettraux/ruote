#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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

require 'digest/md5'

require 'ruote/version'
require 'ruote/extract'
require 'ruote/workitem'
require 'ruote/util/misc'
require 'ruote/util/hashdot'


module Ruote

  # This function is used to generate the subids. Each flow
  # expression receives such an id (it's useful for cursors, loops and
  # forgotten branches).
  #
  def self.generate_subid(salt)

    Digest::MD5.hexdigest(
      "#{rand}-#{salt}-#{$$}-#{Thread.current.object_id}#{Time.now.to_f}")
  end

  #
  # The FlowExpressionId (fei for short) is an process expression identifier.
  # Each expression when instantiated gets a unique fei.
  #
  # Feis are also used in workitems, where the fei is the fei of the
  # [participant] expression that emitted the workitem.
  #
  # Feis can thus indicate the position of a workitem in a process tree.
  #
  # Feis contain four pieces of information :
  #
  # * wfid : workflow instance id, the identifier for the process instance
  # * subid : a unique identifier for expressions (useful in loops)
  # * expid : the expression id, where in the process tree
  # * engine_id : only relevant in multi engine scenarii (defaults to 'engine')
  #
  class FlowExpressionId

    CHILD_SEP = '_'

    attr_reader :h

    def initialize(h)

      @h = h
      class << h; include Ruote::HashDot; end

      sub_wfid = @h.delete('sub_wfid')
      @h['subid'] ||= sub_wfid
        #
        # TODO : for 2.2.2, remove those two lines
    end

    def expid; @h['expid']; end
    def wfid; @h['wfid']; end
    def engine_id; @h['engine_id']; end
    def subid; @h['subid']; end

    alias sub_wfid subid

    def to_storage_id

      "#{@h['expid']}!#{@h['subid']}!#{@h['wfid']}"
    end

    alias sid to_storage_id

    #   expid!subid[0, 5]!wfid
    #
    def short_sid

      "#{@h['expid']}!#{@h['subid'][0, 5]}!#{@h['wfid']}"
    end

    #   wfid!!expid
    #
    def to_sortable_id

      "#{@h['wfid']}!!#{@h['expid']}"
    end

    def self.to_storage_id(hfei)

      # TODO : for 2.1.13, remove the subid || sub_wfid trick

      if hfei.respond_to?(:to_storage_id)
        hfei.to_storage_id
      else
        "#{hfei['expid']}!#{hfei['subid'] || hfei['sub_wfid']}!#{hfei['wfid']}"
      end
    end

    # Turns the result of to_storage_id back to a FlowExpressionId instance.
    #
    def self.from_id(s, engine_id='engine')

      extract("#{engine_id}!#{s}")
    end

    # Returns the last number in the expid. For instance, if the expid is
    # '0_5_7', the child_id will be '7'.
    #
    def child_id

      h.expid.split(CHILD_SEP).last.to_i
    end

    # Returns a rufus-mnemo version of the first 9 hexdigits in the subid.
    #
    def mnemo_id

      Rufus::Mnemo.from_i(@h['subid'][0, 9].to_i(16))
    end

    # For proper hashing and sorting.
    #
    def hash

      to_storage_id.hash
    end

    # For proper hashing and sorting.
    #
    def <=>(other)

      self.to_sortable_id <=> other.to_sortable_id
    end

    # Returns true if the other is a FlowExpressionId instance and it
    # points to the same expression as this one.
    #
    def ==(other)

      return false unless other.is_a?(Ruote::FlowExpressionId)

      (hash == other.hash)
    end

    alias eql? ==

    # Returns child_id... For an expid of '0_1_4', this will be 4.
    #
    def self.child_id(h)

      h['expid'].split(CHILD_SEP).last.to_i
    end

    def to_h

      @h
    end

    # Returns true if other_fei is the fei of a child expression of
    # parent_fei.
    #
    def self.direct_child?(parent_fei, other_fei)

      %w[ wfid engine_id ].each do |k|
        return false if parent_fei[k] != other_fei[k]
      end

      pei = other_fei['expid'].split(CHILD_SEP)[0..-2].join(CHILD_SEP)

      (pei == parent_fei['expid'])
    end

    # Attempts at extracting a FlowExpressionId from the given argument
    # (workitem, string, ...)
    #
    # Uses .extract_h
    #
    def self.extract(arg)

      FlowExpressionId.new(extract_h(arg))
    end

    # Attempts at extracting a FlowExpressionId (as a Hash instance) from the
    # given argument (workitem, string, ...)
    #
    def self.extract_h(arg)

      if arg.is_a?(Hash)
        return arg if arg['expid']
        return arg['fei'] if arg['fei']
      end

      return extract_h(arg.fei) if arg.respond_to?(:fei)
      return arg.h if arg.is_a?(Ruote::FlowExpressionId)
      return arg.h['fei'] if arg.is_a?(Ruote::Workitem)

      if arg.is_a?(String)

        ss = arg.split('!')

        return {
          'engine_id' => ss[-4] || 'engine',
          'expid' => ss[-3],
          'subid' => ss[-2],
          'wfid' => ss[-1]
        }
      end

      raise ArgumentError.new(
        "couldn't extract fei out of instance of #{arg.class}")
    end
  end
end

