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
  #   <if>
  #     <equals field-value="f0" other-value="true" />
  #     <participant ref="alpha" />
  #   </if>
  #
  # It accepts an 'else' clause :
  #
  #   <if>
  #     <equals field-value="f0" other-value="true" />
  #     <participant ref="alpha" />
  #     <participant ref="bravo" />
  #   </if>
  #
  # The 'test' attribute can be used instead of a condition child :
  #
  #   <if test="${f:f0}">
  #     <participant ref="alpha" />
  #   </if>
  #
  # The 'rtest' attribute can be used to embed a condition expressed directly
  # in Ruby :
  #
  #   <if rtest="5 * 12 == 61">
  #     <participant ref="alpha" />
  #   </if>
  #
  # (Note that 'rtest' may only be used if the <tt>:ruby_eval_allowed</tt>
  # parameter has been set in the engine's application_context :
  #
  #   engine.application_context[:ruby_eval_allowed] = true
  #
  # but this is dangerous if the origin of the process defintions to run
  # are not trusted)
  #
  # Used alone with 'test' or 'rtest', the 'if' expression simply sets the
  # the __result__ field of its workitem to the result of its attribute
  # evaluation :
  #
  #   <if test="5 == 6"/>
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

      test = eval_condition(:test, workitem, :not)

      if raw_children.length < 1
        workitem.set_result((test != nil and test != false))
        reply_to_parent(workitem)
        return
      end

      @condition_replied = (test != nil)
        #
        # if the "test" attribute is not used, test will be null

      #store_itself
        # now done in apply_*

      # a warning

      maxchildren = (test == nil) ? 3 : 2

      lwarn {
        "apply() 'if' with more than #{maxchildren} children"
      } if raw_children.size > maxchildren

      # apply next step

      if test != nil
        #
        # apply then or else (condition result known)
        #
        apply_consequence(test, workitem, 0)
      else
        #
        # apply condition
        #
        apply_child(0, workitem)
      end
    end

    def reply (workitem)

      return reply_to_parent(workitem) \
        if @condition_replied

      result = workitem.attributes[FIELD_RESULT]

      @condition_replied = true

      #store_itself
        # now done in apply_c*

      apply_consequence(result, workitem)
    end

    #
    # This reply_to_parent takes care of cleaning all the children
    # before replying to the parent expression, this is important
    # because only the 'then' or the 'else' child got evaluated, the
    # remaining one has to be cleaned out here.
    #
    def reply_to_parent (workitem)

      clean_children
      super(workitem)
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

        if index >= raw_children.length
          reply_to_parent(workitem)
        else
          apply_child(index, workitem)
        end
      end
  end

  #
  # The 'case' expression.
  #
  #   <case>
  #
  #     <equals field="f0" other-value="ready" />
  #     <participant ref="alpha" />
  #
  #     <if test="${supply_level} == ${field:supply_request}" />
  #     <participant ref="bravo" />
  #
  #     <participant ref="charly" />
  #
  #   </case>
  #
  # A generalized 'if'. Will evaluate its children, expecting the order :
  #
  #   - condition
  #   - consequence
  #   - condition
  #   - consequence
  #   ...
  #   - else consequence (optional)
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

      trigger_child(workitem, true)
    end

    def reply (workitem)

      if @evaluating_condition

        trigger_child(workitem, ( ! workitem.get_boolean_result))
      else

        reply_to_parent(workitem)
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

        unless raw_children[@offset]
          reply_to_parent(workitem)
          return
        end

        @evaluating_condition = is_condition

        store_itself

        #get_expression_pool.apply(@children[@offset], workitem)
        apply_child(@offset, workitem)
      end
  end

end

