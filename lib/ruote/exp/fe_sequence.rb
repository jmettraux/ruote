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


module Ruote::Exp

  #
  # The plain 'sequence' expression.
  #
  #   sequence do
  #     participant 'alpha'
  #     participant 'bravo'
  #     participant 'charly'
  #   end
  #
  #
  # == using 'let'
  #
  # 'let' behaves like a sequence, but the children have their own variable
  # scope.
  #
  #   pdef = Ruote.process_definition do
  #     set 'v:var' => 'val'
  #     echo "out:${v:var}"
  #     let do
  #       set 'v:var' => 'val1'
  #       echo "in:${v:var}"
  #     end
  #     echo "out:${v:var}"
  #   end
  #
  # # => out:val, in:val1, out:val
  #
  #
  # == as a 'case' statement
  #
  #   let do
  #     define 'published' do
  #       do_this
  #     end
  #     define 'reviewed' do
  #       do_that
  #     end
  #     subprocess '${case}'
  #   end
  #
  # Subprocesses 'published' and 'reviewed' are bound in a local scope,
  # that gets discarded when the let exits.
  #
  class SequenceExpression < FlowExpression

    names :sequence, :let

    def apply

      h.variables ||= {} if name == 'let'

      reply(h.applied_workitem)
    end

    def reply(workitem)

      position = workitem['fei'] == h.fei ?
        0 : Ruote::FlowExpressionId.new(workitem['fei']).child_id + 1

      if position < tree_children.size
        apply_child(position, workitem)
      else
        reply_to_parent(workitem)
      end
    end
  end
end

