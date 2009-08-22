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


require 'ruote/exp/fe_concurrence'
require 'ruote/exp/iterator'


module Ruote::Exp

  #
  # This expression is a cross between 'concurrence' and 'iterator'.
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
  #
  # == :times and :branches
  #
  # Similarly to the iterator expression, the :times or the :branches attribute
  # may be used in stead of the 'on' attribute.
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     concurrent_iterator :times => 3
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
  # == options
  #
  # the concurrent_iterator accepts the same options for merging as its bigger
  # brother, the concurrence expression.
  #
  # :count, :merge (override, mix, isolate), remaining (cancel, forget) and
  # :over.
  #
  class ConcurrentIteratorExpression < ConcurrenceExpression

    include IteratorMixin

    names :concurrent_iterator

    protected

    def apply_children

      return reply_to_parent(@applied_workitem) unless tree_children[0]

      @list = determine_list

      return reply_to_parent(@applied_workitem) if @list.empty?

      persist

      to_v, to_f = determine_tos
      to_v = 'i' if to_v == nil && to_f == nil

      @list.each_with_index do |e, ii|

        val = @list[ii]

        variables = {}
        workitem  = @applied_workitem.dup

        variables['ii'] = ii

        if to_v
          variables[to_v] = val
        else #if to_f
          workitem.fields[to_f] = val
        end

        pool.launch_sub(
          "#{@fei.expid}_0",
          tree_children[0],
          self,
          workitem,
          :variables => variables)
      end
    end

    # Overrides the implementation found in ConcurrenceExpression
    #
    def expected_count

      @count ? [ @count, @list.size ].min : @list.size
    end
  end
end

