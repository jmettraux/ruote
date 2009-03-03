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
  # Triggers the first (and supposedly unique child of this expression)
  # but never wait for its reply (lose it).
  #
  # A 'lose' expression never replies to its parent expression.
  #
  #   <lose>
  #     <participant ref="toto" />
  #   </lose>
  #
  # Useful only some special process cases (like a concurrence
  # expecting only a certain number of replies).
  #
  # The brother expressions is 'forget', but 'forget' triggers its child
  # and immediately replies, whereas 'lose' doesn't reply.
  #
  class LoseExpression < FlowExpression

    names :lose

    def apply (workitem)

      child = first_expression_child

      return unless child

      apply_child(child, workitem)
    end

    def reply (workitem)

      get_expression_pool.remove(self)
    end
  end

  #
  # This expression triggers its child and then
  # forgets about it. It immediately replies to its parent expression.
  #
  # The brother expression 'lose' triggers its child but never replies to its
  # parent expression.
  #
  # The 'forget' expression is useful for triggering process segments
  # that are, well, dead ends.
  #
  class ForgetExpression < FlowExpression

    names :forget

    def apply (workitem)

      child = first_expression_child

      get_expression_pool.tlaunch_child(
        self,
        child,
        raw_children.index(child),
        workitem.dup,
        :orphan => true,
        :dup_environment => true
      ) if child

      reply_to_parent(workitem)
    end

    def reply (workitem)
      # never gets called
    end
  end

end

