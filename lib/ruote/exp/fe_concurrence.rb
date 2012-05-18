#--
# Copyright (c) 2005-2012, John Mettraux, jmettraux@gmail.com
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


require 'ruote/exp/merge'


module Ruote::Exp

  #
  # The 'concurrence' expression applies its child branches in parallel
  # (well it makes a best effort to make them run in parallel).
  #
  #   concurrence do
  #     alpha
  #     bravo
  #   end
  #
  # == attributes
  #
  # The concurrence expression takes a number of attributes that allow for
  # sophisticated control (especially at merge time).
  #
  # === :count
  #
  #   concurrence :count => 1 do
  #     alpha
  #     bravo
  #   end
  #
  # in that example, the concurrence will terminate as soon as 1 (count) of
  # the branches replies. The other branch will get cancelled.
  #
  # :count and :wait_for may point to a negative integer, meaning "all but
  # x".
  #
  #   concurrence :count => -2 do # all the branches replied but 2
  #     # ...
  #   end
  #
  # :count can be shortened to :c.
  #
  # === :wait_for
  #
  # This attribute accepts either an integer, either a list of tags.
  #
  # When used with the integer, it's equivalent to the :count attribute:
  #
  #   concurrence :wait_for => 1 do
  #     # ...
  #   end
  #
  # It waits for 1 branch to respond and then moves on (concurrence over).
  #
  # When used with a string (or an array), it extracts a list of tags and waits
  # for the branches with those tags. Once all the tags have replied,
  # the concurrence is over.
  #
  #   concurrence :wait_for => 'alpha, bravo' do
  #     sequence :tag => 'alpha' do
  #       # ...
  #     end
  #     sequence :tag => 'bravo' do
  #       # ...
  #     end
  #     sequence :tag => 'charly' do
  #       # ...
  #     end
  #   end
  #
  # This concurrence will be over when the branches alpha and bravo have
  # replied. The charly branch may have replied or not, it doesn't matter.
  #
  # :wait_for can be shortened to :wf.
  #
  # === :remaining
  #
  # As said for :count, the remaining branches get cancelled. By setting
  # :remaining to :forget (or 'forget'), the remaining branches will continue
  # their execution, forgotten.
  #
  #   concurrence :count => 1, :remaining => :forget do
  #     alpha
  #     bravo
  #   end
  #
  # :remaining can be shortened to :rem or :r.
  #
  # The default is 'cancel', where all the remaining branches are cancelled
  # while the hand is given back to the main flow.
  #
  # There is a third setting, 'wait'. It behaves like 'cancel', but the
  # concurrence waits for the cancelled children to reply. The workitems
  # from cancelled branches are merged in as well.
  #
  # === :merge
  #
  # By default, the workitems override each others. By default, the first
  # workitem to reply will win.
  #
  #   sequence do
  #     concurrence do
  #       alpha
  #       bravo
  #     end
  #     charly
  #   end
  #
  # In that example, if 'alpha' replied first, the workitem that reaches
  # 'charly' once 'bravo' replied will have the payload as seen/modified by
  # 'alpha'.
  #
  # The :merge attribute determines which branch wins the merge.
  #
  # * first (default)
  # * last
  # * highest
  # * lowest
  #
  # highest and lowest refer to the position in the list of branch. It's useful
  # to set a fixed winner.
  #
  #   concurrence :merge => :highest do
  #     alpha
  #     bravo
  #   end
  #
  # makes sure that alpha's version of the workitem wins.
  #
  # :merge can be shortened to :m.
  #
  # === :merge_type
  #
  # ==== :override
  #
  # By default, the merge type is set to 'override', which means that the
  # 'winning' workitem's payload supplants all other workitems' payloads.
  #
  # ==== :mix
  #
  # Setting :merge_type to :mix, will actually attempt to merge field by field,
  # making sure that the field value of the winner(s) are used.
  #
  # ==== :isolate
  #
  # :isolate will rearrange the resulting workitem payload so that there is
  # a new field for each branch. The name of each field is the index of the
  # branch from '0' to ...
  #
  # ==== :stack
  #
  # :stack will stack the workitems coming back from the concurrence branches
  # in an array whose order is determined by the :merge attributes. The array
  # is placed in the 'stack' field of the resulting workitem.
  # Note that the :stack merge_type also creates a 'stack_attributes' field
  # and populates it with the expanded attributes of the concurrence.
  #
  # Thus
  #
  #   sequence do
  #     concurrence :merge => :highest, :merge_type => :stack do
  #       reviewer1
  #       reviewer2
  #     end
  #     editor
  #   end
  #
  # will see the 'editor' receive a workitem whose fields look like :
  #
  #   { 'stack' => [{ ... reviewer1 fields ... }, { ... reviewer2 fields ... }],
  #     'stack_attributes' => { 'merge'=> 'highest', 'merge_type' => 'stack' } }
  #
  # This could prove useful for participant having to deal with multiple merge
  # strategy results.
  #
  # ==== :union
  #
  # (Available from ruote 2.3.0)
  #
  # Will override atomic fields, concat arrays and merge hashes...
  #
  # The union of those two workitems
  #
  #   { 'a' => 0, 'b' => [ 'x', 'y' ], 'c' => { 'aa' => 'bb' }
  #   { 'a' => 1, 'b' => [ 'y', 'z' ], 'c' => { 'cc' => 'dd' }
  #
  # will be
  #
  #   { 'a' => 1,
  #     'b' => [ 'x', 'y', 'z' ],
  #     'c' => { 'aa' => 'bb', 'cc' => 'dd' } }
  #
  # Warning: duplicates in arrays present _before_ the merge will be removed
  # as well.
  #
  # ==== :concat
  #
  # (Available from ruote 2.3.0)
  #
  # Much like :union, but duplicates are not removed. Thus
  #
  #   { 'a' => 0, 'b' => [ 'x', 'y' ], 'c' => { 'aa' => 'bb' }
  #   { 'a' => 1, 'b' => [ 'y', 'z' ], 'c' => { 'cc' => 'dd' }
  #
  # will be
  #
  #   { 'a' => 1,
  #     'b' => [ 'x', 'y', 'y', 'z' ],
  #     'c' => { 'aa' => 'bb', 'cc' => 'dd' } }
  #
  # ==== :deep
  #
  # (Available from ruote 2.3.0)
  #
  # Identical to :concat but hashes are merged with deep_merge (ActiveSupport
  # flavour).
  #
  # ==== :ignore
  #
  # (Available from ruote 2.3.0)
  #
  # A very simple merge type, the workitems given back by the branches are
  # simply discarded and the workitem as passed to the concurrence expression
  # is used to reply to the parent expression (of the concurrence expression).
  #
  # :merge_type can be shortened to :mt.
  #
  #
  # === :over_if (and :over_unless) attribute
  #
  # Like the :count attribute controls how many branches have to reply before
  # a concurrence ends, the :over attribute is used to specify a condition
  # upon which the concurrence will [prematurely] end.
  #
  #   concurrence :over_if => '${f:over}'
  #     alpha
  #     bravo
  #     charly
  #   end
  #
  # will end the concurrence as soon as one of the branches replies with a
  # workitem whose field 'over' is set to true. (the remaining branches will
  # get cancelled unless :remaining => :forget is set).
  #
  # :over_unless needs no explanation.
  #
  class ConcurrenceExpression < FlowExpression

    include MergeMixin

    names :concurrence

    COUNT_R = /^-?\d+$/

    def apply

      return do_reply_to_parent(h.applied_workitem) if tree_children.empty?

      #
      # count and wait_for

      count = (attribute(:count) || attribute(:c)).to_s
      count = nil unless COUNT_R.match(count)

      wf = count || attribute(:wait_for) || attribute(:wf)

      if COUNT_R.match(wf.to_s)
        h.ccount = wf.to_i
      elsif wf
        h.wait_for = Ruote.comma_split(wf)
      end

      #
      # other attributes

      h.cmerge = att(
        [ :merge, :m ],
        %w[ first last highest lowest ])
      h.cmerge_type = att(
        [ :merge_type, :mt ],
        %w[ override mix isolate stack union ignore concat deep ])
      h.remaining = att(
        [ :remaining, :rem, :r ],
        %w[ cancel forget wait ])

      h.workitems = (h.cmerge == 'first' || h.cmerge == 'last') ? [] : {}

      h.over = false

      apply_children

      @context.storage.put_msg(
        'reply', 'fei' => h.fei, 'workitem' => h.applied_workitem
      ) if h.ccount == 0
        #
        # force an immediate reply
    end

    def reply(workitem)

      workitem = Ruote.fulldup(workitem)
        #
        # since workitem field merging might happen, better to work on
        # a copy of the workitem (so that history, coming afterwards,
        # doesn't see a modified version of the workitem)

      if h.cmerge == 'first' || h.cmerge == 'last'
        h.workitems << workitem
      else
        h.workitems[workitem['fei']['expid']] = workitem
      end

      if h.wait_for && tag = workitem['fields']['__left_tag__']
        h.wait_for.delete(tag)
      end

      over = h.over
      h.over = over || over?(workitem)

      if (not over) && h.over
        # just became 'over'

        reply_to_parent(nil)

      elsif h.over && h.remaining == 'wait'

        reply_to_parent(nil)

      elsif h.children.empty?

        do_unpersist || return

        @context.storage.put_msg(
          'ceased',
          'wfid' => h.fei['wfid'], 'fei' => h.fei, 'workitem' => workitem)
      else

        do_persist
      end
    end

    protected

    def apply_children

      # a) register children
      # b) persist
      # c) trigger children applies

      msgs = []

      tree_children.each_with_index do |c, i|
        msgs << pre_apply_child(i, h.applied_workitem.dup, false)
      end

      persist_or_raise

      msgs.each { |m| @context.storage.put_msg('apply', m) }
    end

    def over?(workitem)

      over_if = attribute(:over_if, workitem)
      over_unless = attribute(:over_unless, workitem)

      if over_if && Condition.true?(over_if)
        workitem['winner'] = true
        true
      elsif over_unless && (not Condition.true?(over_unless))
        workitem['winner'] = true
        true
      elsif h.wait_for
        h.wait_for.empty?
      else
        (h.workitems.size >= expected_count)
      end
    end

    # How many branch replies are expected before the concurrence is over ?
    #
    def expected_count

      if h.ccount.nil?
        count_list_size
      elsif h.ccount >= 0
        [ h.ccount, count_list_size ].min
      else # all but 1, 2, ...
        i = count_list_size + h.ccount
        i < 1 ? 1 : i
      end
    end

    # (note : concurrent_iterator overrides it)
    #
    def count_list_size

      tree_children.size
    end

    def reply_to_parent(_workitem)

      #
      # remaining 'wait' case first

      if h.remaining == 'wait'

        if h.workitems.size >= count_list_size
          #
          # all children have replied

          workitem = merge_all_workitems

          do_unpersist && super(workitem, false)

        elsif h.children_cancelled == nil
          #
          # the concurrence is over, let's cancel all children and then
          # wait for them

          h.children_cancelled = true
          do_persist

          h.children.each { |i| @context.storage.put_msg('cancel', 'fei' => i) }
        end

        return
      end

      #
      # remaining 'forget' and 'cancel' cases

      workitem = merge_all_workitems

      if h.children.empty?

        do_unpersist && super(workitem, false)

      elsif h.remaining == 'cancel'

        if do_unpersist

          super(workitem, false)

          h.children.each { |i| @context.storage.put_msg('cancel', 'fei' => i) }
        end

      else # h.remaining == 'forget'

        h.variables = compile_variables
        h.forgotten = true

        do_persist && super(workitem, false)
      end
    end

    # Called by #reply_to_parent, returns the unique, merged, workitem that
    # will be fed back to the parent expression.
    #
    def merge_all_workitems

      return h.applied_workitem if h.workitems.size < 1
      return h.applied_workitem if h.cmerge_type == 'ignore'

      wis = case h.cmerge
        when 'first'
          h.workitems.reverse
        when 'last'
          h.workitems
        when 'highest', 'lowest'
          is = h.workitems.keys.sort.collect { |k| h.workitems[k] }
          h.cmerge == 'highest' ? is.reverse : is
      end

      as, bs = wis.partition { |wi| wi.delete('winner') }
      wis = bs + as
        #
        # the 'winner' is the workitem that triggered successfully the
        # :over_if or :over_unless, let's take him precedence in the merge...

      merge_workitems(wis, h.cmerge_type)
    end
  end
end

