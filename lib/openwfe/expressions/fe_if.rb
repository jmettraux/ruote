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

require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/expressions/condition'
require 'openwfe/expressions/flowexpression'


#
# expressions like 'set' and 'unset' and their utility methods
#

module OpenWFE

    #
    # The 'if' expression.
    #
    #     <if>
    #         <equals field-value="f0" other-value="true" />
    #         <participant ref="alpha" />
    #     </if>
    #
    # It accepts an 'else' clause :
    #
    #     <if>
    #         <equals field-value="f0" other-value="true" />
    #         <participant ref="alpha" />
    #         <participant ref="bravo" />
    #     </if>
    #
    # The 'test' attribute can be used instead of a condition child :
    #
    #     <if test="${f:f0}">
    #         <participant ref="alpha" />
    #     </if>
    #
    # The 'rtest' attribute can be used to embed a condition expressed directly
    # in Ruby :
    #
    #     <if rtest="5 * 12 == 61">
    #         <participant ref="alpha" />
    #     </if>
    #
    # (Note that 'rtest' may only be used if the <tt>:ruby_eval_allowed</tt>
    # parameter has been set in the engine's application_context :
    #
    #     engine.application_context[:ruby_eval_allowed] = true
    #
    # but this is dangerous if the origin of the process defintions to run
    # are not trusted)
    #
    # Used alone with 'test' or 'rtest', the 'if' expression simply sets the 
    # the __result__ field of its workitem to the result of its attribute
    # evaluation :
    #
    #     <if test="5 == 6"/>
    #
    # will set the __result__ field of the workitem to 'false'.
    #
    class IfExpression < FlowExpression
        include ConditionMixin

        names :if

        #
        # This boolean is set to true when the conditional claused has
        # been evaluated and the 'if' is waiting for the consequence's
        # reply.
        #
        attr_accessor :condition_replied


        def apply (workitem)

            #workitem.unset_result
                #
                # since OpenWFEru 0.9.16 previous __result__ values
                # are not erased before an 'if'.

            test = eval_condition :test, workitem, :not

            if @children.length < 1
                #workitem.set_result test if test
                workitem.set_result((test != nil and test != false))
                reply_to_parent workitem
                return
            end

            @condition_replied = (test != nil)
                #
                # if the "test" attribute is not used, test will be null

            store_itself

            # a warning

            maxchildren = (test == nil) ? 3 : 2

            lwarn { 
                "apply() 'if' with more than #{maxchildren} children"
            } if @children.size > maxchildren

            # apply next step

            if test != nil
                #
                # apply then or else (condition result known)
                #
                apply_consequence test, workitem, 0
            else
                #
                # apply condition
                #
                get_expression_pool.apply @children.first, workitem
            end
        end

        def reply (workitem)

            return reply_to_parent(workitem) \
                if @condition_replied

            result = workitem.attributes[FIELD_RESULT]

            @condition_replied = true

            store_itself

            apply_consequence result, workitem
        end

        #
        # This reply_to_parent takes care of cleaning all the children
        # before replying to the parent expression, this is important
        # because only the 'then' or the 'else' child got evaluated, the 
        # remaining one has to be cleaned out here.
        #
        def reply_to_parent (workitem)

            clean_children
            super workitem
        end

        protected

            def apply_consequence (index, workitem, offset=1)

                if index == true
                    index = 0
                elsif index == false
                    index = 1
                elsif index == nil
                    index = 1
                elsif not index.integer?
                    index = 0
                end

                index = index + offset

                if index >= @children.length
                    reply_to_parent workitem
                else
                    get_expression_pool.apply @children[index], workitem
                end
            end
    end

    #
    # The 'case' expression.
    #
    #     <case>
    #
    #         <equals field="f0" other-value="ready" />
    #         <participant ref="alpha" />
    #
    #         <if test="${supply_level} == ${field:supply_request}" />
    #         <participant ref="bravo" />
    #
    #         <participant ref="charly" />
    #
    #     </case>
    #
    # A generalized 'if'. Will evaluate its children, expecting the order :
    #
    #     - condition
    #     - consequence
    #     - condition
    #     - consequence
    #     ...
    #     - else consequence (optional)
    #
    # The 'switch' nickname can be used for 'case'.
    #
    class CaseExpression < FlowExpression

        names :case, :switch

        #
        # keeping track of where we are in the case iteration
        #
        attr_accessor :offset

        #
        # set to 'true' when the case expression is actually evaluating
        # a condition (ie not triggering a consequence).
        #
        attr_accessor :evaluating_condition


        def apply (workitem)

            #workitem.unset_result
                #
                # since OpenWFEru 0.9.16 previous __result__ values
                # are not erased before a 'case'.

            @offset = nil

            trigger_child workitem, true
        end

        def reply (workitem)

            if @evaluating_condition

                result = workitem.get_boolean_result

                #ldebug { "reply() result : '#{result.to_s}' (#{result.class})" }

                trigger_child workitem, !result
            else

                reply_to_parent workitem
            end
        end

        protected

            def trigger_child (workitem, is_condition)

                @offset = if !@offset
                    0
                elsif is_condition
                    @offset + 2
                else
                    @offset + 1
                end

                #ldebug { "trigger_child() is_condition ? #{is_condition}" }
                #ldebug { "trigger_child() next offset is #{@offset}" }

                unless @children[@offset]
                    reply_to_parent workitem
                    return
                end

                @evaluating_condition = is_condition

                store_itself

                get_expression_pool.apply(@children[@offset], workitem)
            end
    end

end

