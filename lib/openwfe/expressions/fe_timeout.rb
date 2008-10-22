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

require 'openwfe/expressions/timeout'


module OpenWFE

  #
  # The timeout concept begun with the participant expression. When a
  # participant doesn't reply for a certain amount of time, a specified
  # timeout can get triggered.
  # Sometimes something more complex than a single participant needs a
  # timeout setting, this expression sets a timeout for the expression[s]
  # nested within it.
  #
  #   <timeout after="2d">
  #     <sequence>
  #       (...)
  #     </sequence>
  #   </timeout>
  #
  class TimeoutExpression < FlowExpression
    include TimeoutMixin

    names :timeout

    attr_accessor :applied_workitem

    def apply (workitem)

      return reply_to_parent(workitem) if has_no_expression_child

      @applied_workitem = workitem.dup

      schedule_timeout(workitem, :after)

      apply_child(first_expression_child, workitem)
    end

    #
    # The child expression replies, make sure to unschedule the timeout
    # before replying (to our own parent expression).
    #
    def reply (workitem)

      unschedule_timeout(workitem)

      super
    end

    #
    # Cancel order : cancels the child expression (if applied) and
    # unschedule the timeout (if any).
    #
    def cancel

      get_expression_pool.cancel(@children[0]) if @applied_workitem

      unschedule_timeout(nil)

      super
    end

    #
    # The timeout trigger, cancels the nested process segment (the
    # nested expression).
    #
    def trigger (scheduler)

      ldebug { "trigger() timeout requested for #{@fei.to_debug_s}" }

      set_timedout_flag(@applied_workitem)

      cancel

      reply_to_parent(@applied_workitem)
    end
  end

end

