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
require 'ruote/exp/iterator'


module Ruote

  #
  # Iterating on a list of values
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
  #       participant '${v:v}'
  #     end
  #   end
  #
  class IteratorExpression < FlowExpression
    include IteratorMixin

    names :iterator

    def apply

      return reply_to_parent(@applied_workitem) if tree_children.size < 1

      @list = nil

      reply(@applied_workitem)
    end

    def reply (workitem)

      unless @list

        @list = determine_list
        @to_v = attribute(:to_v) || attribute(:to_var) || attribute(:to_variable)
        @to_f = attribute(:to_f) || attribute(:to_fld) || attribute(:to_field)
        @position = 0

      else

        @position += 1
      end

      val = (@list || [])[@position]

      if val != nil

        if @to_v
          (@variables ||= {})[@to_v] = val
        else #@to_f
          workitem.fields[@to_f] = val
        end

        apply_child(0, workitem)

      else

        reply_to_parent(workitem)
      end
    end
  end
end

