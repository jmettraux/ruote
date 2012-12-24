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


require 'ruote/exp/command'
require 'ruote/exp/iterator'


module Ruote::Exp

  #
  # A parent class for CursorExpression and IteratorExpression
  #
  class CommandedExpression < FlowExpression

    include CommandMixin

    def reply(workitem)

      workitem = h.command_workitem || workitem
      h.command_workitem = nil

      # command/answer may come from
      #
      # a) a child, regular case, easy
      # b) somewhere else, which means we have to cancel the current child
      #    and then make sure the comand is interpreted

      # a)

      if Ruote::FlowExpressionId.direct_child?(h.fei, workitem['fei'])
        return move_on(workitem)
      end

      # b)

      h.command_workitem = workitem
      h.command_workitem['fei'] = h.children.first

      do_persist or return

      @context.storage.put_msg('cancel', 'fei' => h.children.first)

      # iteration will be done at when cancelled child replies
    end
  end
end

