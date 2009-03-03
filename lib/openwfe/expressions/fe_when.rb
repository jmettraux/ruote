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


require 'openwfe/utils'
require 'openwfe/expressions/time'
require 'openwfe/expressions/timeout'
require 'openwfe/expressions/condition'


module OpenWFE

  #
  # The 'when' expression will trigger a consequence when a condition
  # is met, like in
  #
  #   <when test="${variable:over} == true">
  #     <participant ref="toto" />
  #   </when>
  #
  # where the participant "toto" will receive a workitem when the (local)
  # variable "over" has the value true.
  #
  # This is also possible :
  #
  #   <when>
  #     <equals field-value="done" other-value="true" />
  #     <participant ref="toto" />
  #   </when>
  #
  # The 'when' expression by defaults, evaluates every 10 seconds its
  # condition clause.
  # A different frequency can be stated via the "frequency" attribute :
  #
  #   _when :test => "${completion_level} == 4", :frequency => "1s"
  #     participant "next_stage"
  #   end
  #
  # will check for the completion_level value every second. The scheduler
  # itself is by default 'waking up' every 250 ms, so setting a frequency to
  # something smaller than that value might prove useless.
  # (Note than in the Ruby process definition, the 'when' got escaped to
  # '_when' not to conflict with the 'when' keyword of the Ruby language).
  #
  # The when expression understands the 'timeout' attribute like the
  # participant expression does. Thus
  #
  #   _when :test => "${cows} == 'do fly'", :timeout => "1y"
  #     participant "me"
  #   end
  #
  # will timeout after one year (participant "me" will not receive a
  # workitem).
  #
  class WhenExpression < WaitingExpression

    names :when
    conditions :test

    attr_accessor \
      :consequence_triggered,
      :condition_sub_id

    def apply (workitem)

      return reply_to_parent(workitem) if has_no_expression_child

      @condition_sub_id = -1
      @consequence_triggered = false

      super(workitem)
    end

    def reply (workitem)

      return reply_to_parent(workitem) if @consequence_triggered

      super(workitem)
    end

    protected

      def apply_consequence (workitem)

        @consequence_triggered = true

        store_itself

        i = 1
        i = 0 if @children.size == 1

        get_expression_pool.apply(@children[i], workitem)
      end
  end

end

