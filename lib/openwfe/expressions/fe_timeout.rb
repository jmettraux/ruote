#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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

      trigger_on_cancel # if any

      #super
      @applied_workitem
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

