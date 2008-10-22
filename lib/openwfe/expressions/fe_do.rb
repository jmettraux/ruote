#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

require 'openwfe/utils'
require 'openwfe/expressions/flowexpression'


#
# redo / undo (cancel)
#

module OpenWFE

  #
  # Every expression in OpenWFEru accepts a 'tag' attribute. This tag
  # can later be referenced by an 'undo' or 'redo' expression.
  # Tags are active as soon as an expression is applied and they vanish
  # when the expression replies to its parent expression or is cancelled.
  #
  # Calling for the undo of a non-existent tag throws no error, the flow
  # simply resumes.
  #
  #   concurrence do
  #     sequence :tag => "side_job" do
  #       participant "alice"
  #       participant "bob"
  #     end
  #     sequence do
  #       participant "charly"
  #       undo :ref => "side_job"
  #     end
  #   end
  #
  # In this example, as soon as the participant charly is over, the sequence
  # 'side_job' gets undone (cancelled). If the sequence 'side_job' was
  # already over, the "undo" will have no effect.
  #
  class UndoExpression < FlowExpression

    names :undo

    def apply (workitem)

      if tag = lookup_tag(workitem)

        get_workqueue.push(self, :process_tag, tag, workitem)

      else

        reply_to_parent(workitem)
      end
    end

    #
    # Calls the expression pool cancel() method upon the tagged
    # expression.
    #
    def process_tag (tag, workitem)

      ldebug do
        "process_tag() #{fei.to_debug_s} to undo #{tag.fei.to_debug_s}"
      end

      exp = get_expression_pool.fetch_expression(tag.raw_expression.fei)

      get_expression_pool.cancel(tag.raw_expression.fei)

      get_expression_pool.reply_to_parent(exp, tag.workitem, false)
        #
        # 'remove' is set to false, cancel already removed the
        # expression

      undoing_self = tag.fei.ancestor_of?(@fei)

      reply_to_parent(workitem) unless undoing_self
    end

    #def reply (workitem)
    #end

    protected

      def lookup_tag (workitem)

        tagname = lookup_attribute(:ref, workitem)

        tag = lookup_variable(tagname)

        lwarn { "lookup_tag() no tag named '#{tagname}' found" } unless tag

        tag
      end
  end

  #
  # Every expression in OpenWFEru accepts a 'tag' attribute. This tag
  # can later be referenced by an 'undo' or 'redo' expression.
  #
  # Calling for the undo of a non-existent tag throws no error, the flow
  # simply resumes.
  #
  class RedoExpression < UndoExpression

    names :redo

    def process_tag (tag, workitem)

      ldebug { "process_tag() #{fei.to_debug_s} to redo #{tag.fei.to_debug_s}" }

      #
      # cancel

      get_expression_pool.cancel(tag.fei)

      #
      # [re]apply

      tag.raw_expression.application_context = @application_context

      get_expression_pool.apply(tag.raw_expression, tag.workitem)

      reply_to_parent(workitem)
    end
  end

end

