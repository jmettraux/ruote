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


module Ruote::Exp

  class IfExpression < FlowExpression

    names :if

    def apply

      reply(@applied_workitem)
    end

    # called by 'else', 'then' or perhaps 'equals'
    #
    def reply (workitem)

      if workitem.fei == @fei # apply --> reply

        @test = attribute(:test)
        persist

        if @test
          apply_child_if_present(Condition.true?(@test) ? 0 : 1, workitem)
        else
          apply_child_if_present(0, workitem)
        end

      else # reply from a child

        if @test or workitem.fei.child_id != 0
          reply_to_parent(workitem)
        else
          apply_child_if_present(workitem.result == true ? 1 : 2, workitem)
        end
      end
    end

    protected

    def apply_child_if_present (index, workitem)

      if tree_children[index]
        apply_child(index, workitem)
      else
        reply_to_parent(workitem)
      end
    end
  end
end

