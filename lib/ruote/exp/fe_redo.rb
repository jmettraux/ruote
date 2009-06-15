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


module Ruote

  class RedoExpression < FlowExpression

    # TODO : conditional ?

    names :redo, :_redo

    def apply

      ref = attribute(:ref) || attribute_text
      tag = ref ? lookup_variable(ref) : nil

      if tag and exp = expstorage[tag]

        # wire exp's tree to itself on_cancel and cancel

        exp.on_cancel = exp.tree
        exp.persist

        pool.cancel_expression(tag)

        reply_to_parent(@applied_workitem) unless ancestor?(tag)

      else

        reply_to_parent(@applied_workitem)
      end
    end

    def reply (workitem)

      # never called
    end

    def cancel

      reply_to_parent(@applied_workitem)
    end
  end
end

