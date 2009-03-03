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


require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # This expression sequentially executes each of its children expression.
  # For a more sophisticated version of it, see the 'cursor' expression
  # (fe_cursor.rb).
  #
  #   <sequence>
  #     <participant ref="alice" />
  #     <participant ref="service_b" />
  #   </sequence>
  #
  # In a Ruby process definition, it looks like :
  #
  #   sequence do
  #     participant "alice"
  #     participant "service_b"
  #   end
  #
  class SequenceExpression < FlowExpression

    names :sequence

    def apply (workitem)

      reply(workitem)
    end

    def reply (workitem)

      child_index = next_child_index(workitem.fei)

      return reply_to_parent(workitem) unless child_index

      @children.clear if @children
        # keeping track of only 1 child, it's a sequence ...

      apply_child(child_index, workitem)
    end

    protected

    #
    # Returns the child_index (in the raw_children array) of the next child
    # to apply, or nil if the sequence is over.
    #
    def next_child_index (returning_fei)

      next_id = if returning_fei.is_a?(Integer)
        returning_fei + 1
      elsif returning_fei == self.fei
        0
      else
        returning_fei.child_id.to_i + 1
      end

      loop do

        break if next_id > raw_children.length

        raw_child = raw_children[next_id]

        return next_id \
          if raw_child.is_a?(Array) or raw_child.is_a?(FlowExpressionId)

        next_id += 1
      end

      nil
    end
  end

end

