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


require 'openwfe/utils'
require 'openwfe/expressions/value'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # Every expression in Ruote accepts a 'tag' attribute. This tag
  # can later be referenced by an 'undo' or 'redo' expression.
  #
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
  # Note that since Ruote 0.9.20, it's OK to simply write :
  #
  #   undo "side_job"
  #
  # Since Ruote 0.9.20, putting a condition on 'undo' is accepted :
  #
  #   undo 'side_job', :if => '${f:something_went_wrong} == true'
  #
  class UndoExpression < FlowExpression
    include ValueMixin
    include ConditionMixin

    names :undo#, :cancel

    def reply (workitem)

      conditional = eval_condition(:if, workitem, :unless)

      return reply_to_parent(workitem) if conditional == false

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

      ldebug { "process_tag() #{fei.to_debug_s} to undo #{tag.fei.to_debug_s}" }

      exp = get_expression_pool.fetch_expression(tag.raw_expression.fei)

      #
      # cancel target

      get_expression_pool.cancel(tag.raw_expression.fei)

      get_expression_pool.reply_to_parent(exp, tag.workitem, false)
        #
        # 'remove' is set to false, cancel already removed the
        # expression

      undoing_self = tag.fei.ancestor_of?(@fei)

      reply_to_parent(workitem) unless undoing_self
    end

    protected

    def lookup_tag (workitem)

      tagname = workitem.get_result || lookup_attribute(:ref, workitem)
      tagname = tagname.to_s

      return nil unless tagname

      tag = lookup_variable(tagname)

      lwarn { "lookup_tag() no tag named '#{tagname}' found" } unless tag

      tag
    end
  end

  #
  # Every expression in Ruote accepts a 'tag' attribute. This tag
  # can later be referenced by an 'undo' or 'redo' expression.
  #
  # Tags are active as soon as an expression is applied and they vanish
  # when the expression replies to its parent expression or is cancelled.
  #
  # Calling for the undo of a non-existent tag throws no error, the flow
  # simply resumes.
  #
  #   concurrence do
  #     sequence :tag => 'side_job' do
  #       participant 'alice'
  #       participant 'bob'
  #     end
  #     _redo :ref => 'side_job'
  #   end
  #
  # Note that since Ruote 0.9.20, it's OK to simply write :
  #
  #   _redo "that_step"
  #
  # and condition on redo are accepted as well :
  #
  #   <redo ref="that_step" if="${f:misaligned} == true" />
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

