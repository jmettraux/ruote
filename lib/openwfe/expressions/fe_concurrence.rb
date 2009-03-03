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


require 'openwfe/utils'
require 'openwfe/rudefinitions'
require 'openwfe/expressions/merge'
require 'openwfe/expressions/condition'
require 'openwfe/expressions/flowexpression'
require 'openwfe/expressions/iterator'


#
# base expressions like 'sequence' and 'concurrence'
#

module OpenWFE

  #
  # The concurrence expression will execute each of its (direct) children
  # in parallel threads.
  #
  # Thus,
  #
  #   <concurrence>
  #     <participant ref="pa" />
  #     <participant ref="pb" />
  #   </concurrence>
  #
  # Participants pa and pb will be 'treated' in parallel (quasi
  # simultaneously).
  #
  # The concurrence expressions accept many attributes, that can get
  # combined. By default, the concurrence waits for all its children to
  # reply and returns the workitem of the first child that replied.
  # The attributes tune this behaviour.
  #
  # <em>count</em>
  #
  #   <concurrence count="1">
  #     <participant ref="pa" />
  #     <participant ref="pb" />
  #   </concurrence>
  #
  # The concurrence will be over as soon as 'pa' or 'pb' replied, i.e.
  # as soon as "1" child replied.
  #
  # <em>remaining</em>
  #
  # The attribute 'remaining' can take two values 'cancel' (the default) and
  # 'forget'.
  # Cancelled children are completely wiped away, forgotten ones continue
  # to operate but their reply will simply get discarded.
  #
  # <em>over-if</em>
  #
  # 'over-if' accepts a 'boolean expression' (something replying 'true' or
  # 'false'), if the expression evaluates to true, the concurrence will be
  # over and the remaining children will get cancelled (the default) or
  # forgotten.
  #
  # <em>merge</em>
  #
  # By default, the first child to reply to its parent 'concurrence'
  # expression 'wins', i.e. its workitem is used for resuming the flow (after
  # the concurrence).
  #
  # [first]  The default : the first child to reply wins
  # [last]   The last child to reply wins
  # [highest]  The first 'defined' child (in the list of children) will win
  # [lowest]   The last 'defined' child (in the list of children) will win
  #
  # Thus, in that example
  #
  #   <concurrence merge="lowest">
  #     <participant ref="pa" />
  #     <participant ref="pb" />
  #   </concurrence>
  #
  # when the concurrence is done, the workitem of 'pb' is used to resume the
  # flow after the concurrence.
  #
  # <em>merge-type</em>
  #
  # [override]  The default : no mix of values between the workitems do occur
  # [mix]     Priority is given to the 'winning' workitem but their values
  #       get mixed
  # [isolate]   the attributes of the workitem of each branch is placed
  #       in a field in the resulting workitem. For example, the
  #       attributes of the first branch will be stored under the
  #       field named '0' of the resulting workitem.
  #
  # The merge occurs are the top level of workitem attributes.
  #
  # More complex merge behaviour can be obtained by extending the
  # GenericSyncExpression class. But the default sync options are already
  # numerous and powerful by their combinations.
  #
  class ConcurrenceExpression < SequenceExpression
    include ConditionMixin

    names :concurrence

    attr_accessor :sync_expression

    def apply (workitem)

      extract_children # initializes the @children array

      do_apply(workitem)
    end

    def reply (workitem)

      @sync_expression.reply(self, workitem)
    end

    protected

    def do_apply (workitem)

      sync = lookup_sym_attribute(:sync, workitem, :default => :generic)

      @sync_expression =
        get_expression_map.get_sync_class(sync).new(self, workitem)

      @children.each do |child|
        @sync_expression.add_child(child)
      end

      store_itself

      @children.each_with_index do |child, index|

        get_expression_pool.apply(child, get_workitem(workitem, index))
      end

      reloaded_self, _fei = get_expression_pool.fetch(@fei)
      reloaded_self.sync_expression.ready(reloaded_self)
    end

    def get_workitem (workitem, index)

      workitem.dup
    end
  end

  #
  # This expression is a mix between a 'concurrence' and an 'iterator'.
  # It understands the same attributes and behaves as an interator that
  # forks its children concurrently.
  #
  # Some examples :
  #
  #   <concurrent-iterator on-value="sales, logistics, lob2" to-field="p">
  #     <participant field-ref="p" />
  #   </concurrent-iterator>
  #
  # Within a Ruby process definition :
  #
  #   sequence do
  #     set :field => f, :value => %w{ Alan, Bob, Clarence }
  #     #...
  #     concurrent_iterator :on_field => "f", :to_field => "p" do
  #     participant "${p}"
  #     end
  #   end
  #
  class ConcurrentIteratorExpression < ConcurrenceExpression

    names :concurrent_iterator

    def apply (workitem)

      return reply_to_parent(workitem) if has_no_expression_child

      @workitems = []

      iterator = Iterator.new(self, workitem)

      return reply_to_parent(workitem) \
        unless iterator.has_next?

      while iterator.has_next?

        wi = workitem.dup
        vars = iterator.next(wi)
        @workitems << wi

        get_expression_pool.tprepare_child(
          self,
          raw_children.first,
          iterator.index,
          :register_child => true,
          :dont_store_parent => true,
          :variables => vars)
      end

      store_itself

      do_apply(workitem)
    end

    protected

    def get_workitem (wi, index)

      @workitems[index]
    end
  end

  #
  # A base for sync expressions, currently empty.
  # That may change.
  #
  class SyncExpression < ObjectWithMeta

    def initialize

      super
    end

    def self.names (*exp_names)

      exp_names = exp_names.collect do |n|
        n.to_s
      end
      meta_def :expression_names do
        exp_names
      end
    end
  end

  #
  # The classical OpenWFE sync expression.
  # Used by 'concurrence' and 'concurrent-iterator'
  #
  class GenericSyncExpression < SyncExpression

    names :generic

    attr_accessor \
      :remaining_children,
      :count,
      :reply_count,
      :cancel_remaining,
      :unready_queue

    def initialize (synchable, workitem)

      super()

      @remaining_children = []
      @reply_count = 0

      @count = determine_count(synchable, workitem)
      @cancel_remaining = cancel_remaining?(synchable, workitem)

      merge = synchable.lookup_sym_attribute(
        :merge, workitem, :default => :first)

      merge_type = synchable.lookup_sym_attribute(
        :merge_type, workitem, :default => :mix)

      synchable.ldebug { "new() merge_type is '#{merge_type}'" }

      @merge_array = MergeArray.new synchable.fei, merge, merge_type

      @unready_queue = []
    end

    #
    # when all the children got applied concurrently, the concurrence
    # calls this method to notify the sync expression that replies
    # can be processed
    #
    def ready (synchable)

      synchable.ldebug do
        "ready() called by  #{synchable.fei.to_debug_s}  " +
        "#{@unready_queue.length} wi waiting"
      end

      queue = @unready_queue
      @unready_queue = nil
      synchable.store_itself

      queue.each { |workitem| break if do_reply(synchable, workitem) }
        #
        # do_reply() will return 'true' as soon as the
        # concurrence is over, if this is the case, the
        # queue should not be treated anymore
    end

    def add_child (child)

      @remaining_children << child
    end

    def reply (synchable, workitem)

      if @unready_queue

        @unready_queue << workitem

        synchable.store_itself

        synchable.ldebug do
          "#{self.class}.reply() "+
          "#{@unready_queue.length} wi waiting..."
        end

      else

        do_reply(synchable, workitem)
      end
    end

    protected

    def do_reply (synchable, workitem)

      synchable.ldebug do
        "#{self.class}.do_reply() from " +
        "#{workitem.last_expression_id.to_debug_s}"
      end

      @merge_array.push(synchable, workitem)

      @reply_count = @reply_count + 1

      @remaining_children.delete(workitem.last_expression_id)

      if @over #over
        #
        # sync is over, don't determine it again
        #
        synchable.store_itself
        return true
      end

      if @remaining_children.length <= 0

        reply_to_parent(synchable)
        return true
      end

      if @count > 0 and @reply_count >= @count

        @over = true
        synchable.store_itself

        #treat_remaining_children(synchable)
        synchable.get_workqueue.push(
          self, :treat_remaining_children, synchable)

        return true
      end

      #
      # over-if

      if synchable.eval_condition('over-if', workitem, 'over-unless')

        @over = true
        synchable.store_itself

        #treat_remaining_children(synchable)
        synchable.get_workqueue.push(
          self, :treat_remaining_children, synchable)

        return true
      end

      #
      # not over, resuming

      synchable.store_itself

      false
    end

    def reply_to_parent (synchable)

      workitem = @merge_array.do_merge

      synchable.reply_to_parent(workitem)
    end

    def treat_remaining_children (synchable)

      @remaining_children.each do |child|

        synchable.ldebug do
          "#{self.class}.treat_remainining_children() " +
          "#{child.to_debug_s} " +
          "(cancel ? #{@cancel_remaining})"
        end

        if @cancel_remaining
          synchable.get_expression_pool.cancel(child)
        else
          synchable.get_expression_pool.forget(synchable, child)
        end
      end

      reply_to_parent(synchable)
    end

    def cancel_remaining? (synchable_expression, workitem)

      s = synchable_expression.lookup_sym_attribute(
        :remaining, workitem, :default => :cancel)

      (s == :cancel)
    end

    def determine_count (synchable_expression, workitem)

      c = synchable_expression.lookup_attribute(:count, workitem)
      return -1 if not c
      i = c.to_i
      i < 1 ? -1 : i
    end

    #
    # This inner class is used to gather workitems (via push()) before
    # the final merge
    # This final merge is triggered by calling the do_merge() method
    # which will return the resulting, merged workitem.
    #
    class MergeArray
      include MergeMixin

      attr_accessor \
        :synchable_fei,
        :workitem,
        :workitems_by_arrival,
        :workitems_by_altitude,
        :merge,
        :merge_type

      def initialize (synchable_fei, merge, merge_type)

        @synchable_fei = synchable_fei

        @merge = merge
        @merge_type = merge_type

        ensure_merge_settings

        @workitem = nil

        if highest? or lowest?
          @workitems_by_arrival = []
          @workitems_by_altitude = []
        end
      end

      def push (synchable, wi)

        if isolate?
          push_in_isolation(wi)
        elsif last? or first?
          push_by_position(wi)
        else
          push_by_arrival(wi)
        end
      end

      def push_by_position (wi)

        source, target = if first?
          [ @workitem, wi ]
        else
          [ wi, @workitem ]
        end
        @workitem = merge_workitems(target, source, override?)
      end

      def push_in_isolation (wi)

        unless @workitem
          @workitem = wi.dup
          att = @workitem.attributes
          @workitem.attributes = {}
        end

        key = get_child_id(wi)

        @workitem.attributes[key.to_s] = OpenWFE.fulldup(wi.attributes)
      end

      def push_by_arrival (wi)

        #index = synchable.children.index wi.last_expression_id
        #index = Integer(wi.last_expression_id.child_id)
        index = Integer(get_child_id(wi))

        @workitems_by_arrival << wi
        @workitems_by_altitude[index] = wi
      end

      #
      # merges the workitems stored here
      #
      def do_merge

        return @workitem if @workitem

        list = if first?
          @workitems_by_arrival.reverse
        elsif last?
          @workitems_by_arrival
        elsif highest?
          @workitems_by_altitude.reverse
        elsif lowest?
          @workitems_by_altitude
        end

        list.inject(nil) do |result, wi|
          result = merge_workitems(result, wi, override?) if wi
          result
        end
      end

      protected

      def first?
        @merge == :first
      end
      def last?
        @merge == :last
      end
      def highest?
        @merge == :highest
      end
      def lowest?
        @merge == :lowest
      end

      def mix?
        @merge_type == :mix
      end
      def override?
        @merge_type == :override
      end
      def isolate?
        @merge_type == :isolate
      end

      #
      # Returns the child id of the expression that just
      # replied with the given workitem.
      #
      def get_child_id (workitem)

        return workitem.fei.child_id \
          if workitem.fei.wfid == @synchable_fei.wfid

        workitem.fei.last_sub_instance_id
      end

      #
      # Making sure @merge and @merge_type are set to
      # appropriate values.
      #
      def ensure_merge_settings

        @merge_type = :mix unless override? or isolate?
        @merge = :first unless last? or highest? or lowest?
      end
    end

  end

end

