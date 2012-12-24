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


require 'ruote/exp/fe_concurrence'
require 'ruote/exp/iterator'


module Ruote::Exp

  #
  # This expression is a cross between 'concurrence' and 'iterator'.
  #
  # Please look at the documentation of 'iterator' to learn more about the
  # common options between 'iterator' and 'concurrent-iterator'.
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     concurrent_iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
  #       participant '${v:v}'
  #     end
  #   end
  #
  # will be equivalent to
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     concurrence do
  #       participant 'alice'
  #       participant 'bob'
  #       participant 'charly'
  #     end
  #   end
  #
  # The 'on' and the 'to' attributes follow exactly the ones for the iterator
  # expression.
  #
  # When there is no 'to', the current iterated value is placed in the variable
  # named 'i'.
  #
  # The variable named 'ii' contains the current iterated index (an int bigger
  # or egal to 0).
  #
  # 'concurrent_iterator' does not understand commands like
  # rewind/break/jump/... like 'iterator' does, since it fires all its
  # branches when applied.
  #
  # == :on and arrays
  #
  # Given a workitem field named 'x' containing the array value
  # [ 'a', 'b', 'c' ] and a workitem field 'y' containing the string 'a, b, c',
  # this:
  #
  #   concurrent_iterator :on_field => 'x', :to_f => 'xx' do
  #     # ...
  #   end
  #
  # is equivalent to
  #
  #   concurrent_iterator :on => '$f:x', :to_f => 'xx' do
  #     # ...
  #   end
  #
  # is equivalent to
  #
  #   concurrent_iterator :on => '${f:y}', :to_f => 'xx' do
  #     # ...
  #   end
  #
  # == :to_field and :to_f, :to_var and :to_v, :to
  #
  # Those 4 lines are equivalent:
  #
  #     concurrent_iterator :on => [ 'ceo', 'cto' ], :to_field => 'a' do ...
  #     concurrent_iterator :on => [ 'ceo', 'cto' ], :to_f => 'a' do ...
  #     concurrent_iterator :on => [ 'ceo', 'cto' ], :to => 'f:a' do ...
  #     concurrent_iterator :on => [ 'ceo', 'cto' ], :to => 'a' do ...
  #
  # Those 3 lines are equivalent:
  #
  #     concurrent_iterator :on => [ 'ceo', 'cto' ], :to_var => 'a' do ...
  #     concurrent_iterator :on => [ 'ceo', 'cto' ], :to_v => 'a' do ...
  #     concurrent_iterator :on => [ 'ceo', 'cto' ], :to => 'v:a' do ...
  #
  # == :times and :branches
  #
  # Similarly to the iterator expression, the :times or the :branches attribute
  # may be used in stead of the 'on' attribute.
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     concurrent_iterator :times => 3 do
  #       participant 'user${v:i}'
  #     end
  #   end
  #
  # is equivalent to
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     concurrence do
  #       participant 'user0'
  #       participant 'user1'
  #       participant 'user2'
  #     end
  #   end
  #
  #
  # == ruote 2.3.0 and the citerator children
  #
  # Prior to ruote 2.3.0, the concurrent-iterator only considered one child
  # expression:
  #
  #   concurrent_iterator :times => 3 do
  #     participant 'al'
  #     participant 'bob' # 'bob' would never be reached
  #   end
  #
  # So one had to write:
  #
  #   concurrent_iterator :times => 3 do
  #     sequence do
  #       participant 'al'
  #       participant 'bob' # 'bob' would never be reached
  #     end
  #   end
  #
  # Ruote 2.3.0 lifts that restriction.
  #
  #
  # == options
  #
  # the concurrent_iterator accepts the same options for merging as its bigger
  # brother, the concurrence expression.
  #
  # :count, :merge (override, mix, isolate, stack, union, concat, deep, ignore),
  # :remaining (cancel, forget) and :over.
  #
  #
  # == add branches
  #
  # The 'add_branches'/'add_branch' expression can be used to add branches
  # to a concurrent-iterator while it is running.
  #
  #   concurrent_iterator :on => 'a, b, c' do
  #     sequence do
  #       participant :ref => 'worker_${v:i}'
  #       add_branches 'd, e', :if => '${v:/not_sufficient}'
  #     end
  #   end
  #
  # In this example, if the process level variable 'not_sufficient' is set to
  # true, workers d and e will be added to the iterated elements.
  #
  # Read more at the 'add_branches' expression description.
  #
  #
  # == 'citerator'
  #
  # 'citerator' is an alias for 'concurrent_iterator'.
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     citerator :on_val => 'alice, bob, charly', :to_var => 'v' do
  #       participant '${v:v}'
  #     end
  #   end
  #
  class ConcurrentIteratorExpression < ConcurrenceExpression

    include IteratorMixin

    names :concurrent_iterator, :citerator

    ADD_BRANCHES_FIELD = '__add_branches__'

    # Overrides FlowExpression#register_child to make sure that persist is
    # not called.
    #
    def register_child(fei)

      h.children << fei
    end

    def add_branches(list)

      if h.times_iterator && list.size == 1

        count = (list.first.to_i rescue nil)

        list = (h.list_size + 0...h.list_size + count) if count
      end

      list.each do |val|

        h.list_size += 1

        workitem = Ruote.fulldup(h.applied_workitem)

        variables = { 'ii' => h.list_size - 1 }

        if h.to_v
          variables[h.to_v] = val
        else #if to_f
          workitem['fields'][h.to_f] = val
        end

        expid, subtree = if tree_children.size > 1
          [ h.fei['expid'], [ 'sequence', {}, tree_children ] ]
        else
          [ "#{h.fei['expid']}_0", tree_children[0] ]
        end

        launch_sub(
          expid,
          subtree,
          :workitem => workitem,
          :variables => variables,
          :child_id => h.list_size - 1)
      end
    end

    def reply(workitem)

      if ab = workitem['fields'].delete(ADD_BRANCHES_FIELD)

        add_branches(ab)

        if
          h.fei['wfid'] != workitem['fei']['wfid'] ||
          ( ! workitem['fei']['expid'].match(/^#{h.fei['expid']}_\d+$/))
        then
          do_persist
          return
        end
      end

      super(workitem)
    end

    protected

    def apply_children

      return reply_to_parent(h.applied_workitem) unless tree_children[0]

      list = determine_list

      return reply_to_parent(h.applied_workitem) if list.empty?

      h.to_v, h.to_f = determine_tos
      h.to_v = 'i' unless h.to_v or h.to_f

      h.list_size = 0

      add_branches(list)

      persist_or_raise
    end

    # Overrides the implementation found in ConcurrenceExpression
    #
    def count_list_size

      h.list_size
    end

    # TODO
    #
    def workitem_index(workitem)

      if %w[ highest lowest ].include?(h.cmerge)
        nil
      elsif m = workitem['fei']['subid'].match(/k(\d)+$/)
        m[1].to_i
      else
        nil
      end
    end
  end
end

