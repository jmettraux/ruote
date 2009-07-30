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


module Ruote

  class ConcurrentIteratorExpression < ConcurrenceExpression

    include IteratorMixin

    names :concurrent_iterator

    protected

    def apply_children

      return reply_to_parent(@applied_workitem) unless tree_children[0]

      list = determine_list
      to_v, to_f = determine_tos

      return reply_to_parent(@applied_workitem) if list.empty?

      list.each_with_index do |e, i|

        val = list[i]

        variables = {}
        workitem  = @applied_workitem.dup

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
  end
end

