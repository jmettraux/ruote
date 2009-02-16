#
#--
# Copyright (c) 2006-2009, John Mettraux, OpenWFE.org
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

