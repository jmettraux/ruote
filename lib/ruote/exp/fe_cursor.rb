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


module Ruote

  class CursorExpression < FlowExpression

    include CommandMixin

    names :cursor, :loop

    def apply

      reply(@applied_workitem)
    end

    def reply (workitem)

      position = workitem.fei == self.fei ? -1 : workitem.fei.child_id
      position += 1

      com, arg = get_command(workitem)

      return reply_to_parent(workitem) if com == 'break'

      case com
      when 'rewind', 'continue' then position = 0
      when 'skip' then position += arg
      when 'jump' then position = jump_to(workitem, position, arg)
      end

      position = 0 if position == tree_children.size && name == 'loop'

      if position < tree_children.size
        apply_child(position, workitem)
      else
        reply_to_parent(workitem)
      end
    end

    protected

    def jump_to (workitem, position, arg)

      pos = Integer(arg) rescue nil

      return pos if pos != nil

      tree_children.each_with_index do |c, i|

        tag = c[1]['tag']
        next unless tag

        tag = Ruote.dosub(tag, self, workitem)
        next if tag != arg

        pos = i
        break
      end

      pos ? pos : position
    end
  end
end

