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


require 'ruote/exp/flowexpression'
require 'ruote/exp/merge'
require 'ruote/exp/ticket'


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
  #   concurrence :merge => highest do
  #     alpha
  #     bravo
  #   end
  #
  # makes sure that alpha's version of the workitem wins.
  #
  # === :merge_type
  #
  # By default, the merge type is set to 'override', which means that the
  # 'winning' workitem's payload supplants all other workitems' payloads.
  #
  # Setting :merge_type to :mix, will actually attempt to merge field by field,
  # making sure that the field value of the winner(s) are used.
  #
  # :isolate will rearrange the resulting workitem payload so that there is
  # a new field for each branch. The name of each field is the index of the
  # branch from '0' to ...
  #
  #
  # === :over_if (and :over_unless)
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
    include TicketMixin

    names :concurrence

    # TODO : implement :over_unless

    def apply

      @count = attribute(:count).to_i rescue nil
      @count = nil if @count && @count < 1

      @merge = att(:merge, %w[ first last highest lowest ])
      @merge_type = att(:merge_type, %w[ override mix isolate ])
      @remaining = att(:remaining, %w[ cancel forget ])

      @workitems = (@merge == 'first' || @merge == 'last') ? [] : {}

      @over = false

      apply_children
    end

    def reply (workitem)

      if not @over

        if @merge == 'first' || @merge == 'last'
          @workitems << workitem
        else
          @workitems[workitem.fei.expid] = workitem
        end

        @over = over?(workitem)

        persist

        reply_to_parent(nil) if @over
      end
    end

    # wraps the reply method with the ticket mechanism
    #
    with_ticket :reply

    protected

    def apply_children

      tree_children.each_with_index do |c, i|
        apply_child(i, @applied_workitem.dup)
      end
    end

    def over? (workitem)

      over_if = attribute(:over_if, workitem)
      over_unless = attribute(:over_unless, workitem)

      if over_if && Condition.true?(over_if)
        true
      elsif over_unless && (not Condition.true?(over_unless))
        true
      else
        (@workitems.size >= expected_count)
      end
    end

    # How many branch replies are expected before the concurrence is over ?
    #
    # (note : concurrent_iterator overrides it)
    #
    def expected_count

      @count ? [ @count, tree_children.size ].min : tree_children.size
    end

    def reply_to_parent (_workitem)

      handle_remaining if @children

      discard_all_tickets

      super(merge_all_workitems)
    end

    def merge_all_workitems

      return @applied_workitem if @workitems.size < 1

      wis = case @merge
      when 'first'
        @workitems.reverse
      when 'last'
        @workitems
      when 'highest', 'lowest'
        is = @workitems.keys.sort.collect { |k| @workitems[k] }
        @merge == 'highest' ? is.reverse : is
      end
      rwis = wis.reverse

      wis.inject(nil) { |t, wi|
        merge_workitems(rwis.index(wi), t, wi, @merge_type)
      }
    end

    def handle_remaining

      b = @remaining == 'cancel' ?
        lambda { |fei| pool.cancel_expression(fei, nil) } :
        lambda { |fei| pool.forget_expression(fei) }

      @children.each(&b)
    end
  end
end

