#
#--
# Copyright (c) 2006-2008, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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

      get_expression_pool.apply(children[0], workitem) \
        if (@children and @children.length > 0)
    end

    def reply (workitem)

      get_expression_pool.remove self
    end
  end

  #
  # This expression triggers its child (in its own thread) and then
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

      if (@children and @children.length > 0)

        wi = workitem.dup

        child = @children[0]
        get_expression_pool.forget self, child
        get_expression_pool.apply child, wi
      end

      reply_to_parent workitem
    end

    def reply (workitem)
      # never gets called
    end
  end

end

