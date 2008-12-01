#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
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


module OpenWFE

  #
  # The 'error' expression provokes an error to occur in a process instance.
  # The error might then be treated by an error handler ('on_error' attribute)
  # or simply registered in the error journal and manually replayed.
  #
  #   sequence do
  #     participant :ref => 'unit1'
  #     error 'missing info', :if => "${f:customer} == ''"
  #     participant :ref => 'unit2'
  #   end
  #
  # In this hypothetical example, the error is triggered if the field customer
  # is empty.
  #
  # == replaying
  #
  # The error expression can be replayed without further ado (though it is
  # expected that the problem it raised attention to has be fixed). At replay
  # the expression will simply let the process instance resume.
  #
  # == on_error
  #
  # This expression can be used to let a process interrupt itself (replay case)
  # or to force the process into a 'fail path' (out of the 'happy path')
  #
  #   class MyDef0 < OpenWFE::ProcessDefinition
  #
  #     sequence :on_error => 'fail_path' do
  #
  #       participant :ref => 'unit1'
  #       error 'missing info', :if => "${f:customer} == ''"
  #       participant :ref => 'unit2'
  #     end
  #
  #     process_definition :name => 'fail_path' do
  #       # ... problem resolution subprocess ...
  #     end
  #   end
  #
  #
  class ErrorExpression < FlowExpression
    include ValueMixin
    include ConditionMixin

    #names :error, :exception
    names :error

    #
    # is set to true when the expression got applied once (and raised
    # its error).
    #
    attr_accessor :triggered


    def reply (workitem)

      return reply_to_parent(workitem) if @triggered
        #
        # when error is 'replayed' simply reply to parent to let flow resume

      conditional = eval_condition(:if, workitem, :unless)

      return reply_to_parent(workitem) if conditional == false

      text = workitem.get_result.to_s

      @triggered = true

      store_itself # making sure @triggered is saved

      raise(ForcedError.new(text))
    end
  end

end

