#
#--
# Copyright (c) 2007-2009, John Mettraux, OpenWFE.org
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

require 'openwfe/expressions/condition'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # This expression cancels the current process instance. Use with care.
  #
  #   <sequence>
  #     <participant ref="before" />
  #     <cancel-process />
  #     <participant ref="after" />
  #   </sequence>
  #
  # the message "after" will never get printed.
  #
  # Use rather in scenarii like that one :
  #
  #   class TestDefinition1 < ProcessDefinition
  #     def make
  #       process_definition :name => "25_cancel", :revision => "1" do
  #         sequence do
  #           participant "customer"
  #           _cancel_process :if => "${f:no_thanks} == true"
  #           concurrence do
  #             participant "accounting"
  #             participant "logistics"
  #           end
  #         end
  #       end
  #     end
  #   end
  #
  # Note that the expression accepts an "if" attribute.
  #
  class CancelProcessExpression < FlowExpression
    include ConditionMixin

    names :cancel_process, :cancel_flow

    #
    # apply / reply

    def apply (workitem)

      conditional = eval_condition(:if, workitem, :unless)
        #
        # for example : <cancel-process if="${approved} == false"/>

      return reply_to_parent(workitem) \
        if conditional == false

      #
      # else, do cancel the process

      get_expression_pool.cancel_process(self)

      # no need to reply to parent
    end

    #def reply (workitem)
    #end

  end

end

