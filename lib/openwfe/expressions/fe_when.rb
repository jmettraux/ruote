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

require 'openwfe/utils'
require 'openwfe/expressions/time'
require 'openwfe/expressions/timeout'
require 'openwfe/expressions/condition'


#
# 'when' and 'wait'
#

module OpenWFE

    #
    # The 'when' expression will trigger a consequence when a condition
    # is met, like in
    #
    #     <when test="${variable:over} == true">
    #         <participant ref="toto" />
    #     </when>
    #
    # where the participant "toto" will receive a workitem when the (local)
    # variable "over" has the value true.
    #
    # This is also possible :
    #
    #     <when>
    #         <equals field-value="done" other-value="true" />
    #         <participant ref="toto" />
    #     </when>
    #
    # The 'when' expression by defaults, evaluates every 10 seconds its
    # condition clause.
    # A different frequency can be stated via the "frequency" attribute :
    #
    #     _when :test => "${completion_level} == 4", :frequency => "1s"
    #         participant "next_stage"
    #     end
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
    #     _when :test => "${cows} == 'do fly'", :timeout => "1y"
    #         participant "me"
    #     end
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

            return reply_to_parent(workitem) \
                if raw_children.size < 1

            @condition_sub_id = -1
            @consequence_triggered = false

            super workitem
        end

        def reply (workitem)

            #ldebug do 
            #    "reply() @consequence_triggered is '#{@consequence_triggered}'"
            #end

            return reply_to_parent(workitem) \
                if @consequence_triggered

            super workitem
        end

        protected

            def apply_consequence (workitem)

                @consequence_triggered = true

                store_itself

                i = 1
                i = 0 if @children.size == 1

                get_expression_pool.apply @children[i], workitem
            end
    end

end

