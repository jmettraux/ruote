#
#--
# Copyright (c) 2007, John Mettraux, OpenWFE.org
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

require 'openwfe/expressions/fe_when'


module OpenWFE

  #
  # The 'wait' expression simply blocks/waits until the given condition
  # evaluates to true.
  # This expression accepts a timeout (else it will block ad eternam).
  #
  #   sequence do
  #     wait :until => "${done} == true"
  #     participant :toto
  #   end
  #
  # Participant 'toto' will receive a workitem after the variable 'done' is
  # set to true (somewhere else in the process definition).
  #
  #   sequence do
  #     wait :runtil => "Time.new.to_i % 7 == 0"
  #     participant :toto
  #   end
  #
  # Participant 'toto' will receive a workitem after a certain condition
  # expressed directly in Ruby evaluates to true.
  #
  # 'wait' is different than 'when' : when it times out (if a timeout is set,
  # the wait ceases and the flow resumes. On a timeout, 'when' will not
  # execute its nested 'consequence' child.
  #
  class WaitExpression < WaitingExpression

    names :wait
    conditions :until
  end

end

