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
require 'ruote/exp/command'
require 'ruote/exp/iterator'


module Ruote::Exp

  #
  # Iterating on a list of values
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
  #       participant '${v:v}'
  #     end
  #   end
  #
  # TODO : document :times and :branches
  #
  class IteratorExpression < FlowExpression

    include CommandMixin
    include IteratorMixin

    names :iterator

    def apply

      return reply_to_parent(@applied_workitem) if tree_children.size < 1

      @list = determine_list
      @to_v, @to_f = determine_tos
      @position = -1

      reply(@applied_workitem)
    end

    def reply (workitem)

      @position += 1

      com, arg = get_command(workitem)

      return reply_to_parent(workitem) if com == 'break'

      case com
      when 'rewind', 'continue' then @position = 0
      when 'skip' then @position += arg
      when 'jump' then @position = arg
      end

      @position = @list.length + @position if @position < 0

      val = @list[@position]

      return reply_to_parent(workitem) if val == nil

      if @to_v
        (@variables ||= {})[@to_v] = val
      else #@to_f
        workitem.fields[@to_f] = val
      end
        # TODO : add implicit to_v 'i' here

      apply_child(0, workitem)
    end
  end
end

