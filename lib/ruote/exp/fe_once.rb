#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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


module Ruote::Exp

  #
  # The 'once' / 'when' expression verifies if a condition is true,
  # if not it will block and after 10 seconds it will check again.
  # If true, it will resume or it will execute its child expression (before
  # resuming).
  #
  #   concurrence do
  #
  #     once '${v:/invoice_status} == emitted' do
  #       open_customer_support_account
  #     end
  #
  #     sequence do
  #       participant 'accounting'
  #       set 'v:/invoice_status' => 'emitted'
  #       participant 'accounting 2'
  #     end
  #   end
  #
  # The condition is usually something about variables, since the workitem that
  # this expression has access to is always the one that reached it, at apply
  # time.
  #
  # Without a child expression, this expression behaves in a 'blocking way', and
  # it makes most sense in a 'sequence' or in a 'cursor'.
  #
  #   sequence do
  #     first_stage
  #     once '${v:ready_for_second_stage}'
  #     second_stage
  #   end
  #
  # When there is a child expression, it will get triggered when the condition
  # realizes. Only 1 child expression is accepted, there is no implicit
  # 'sequence'.
  #
  #   concurrence do
  #     once :test => '${v:go_on} == yes' do
  #       subprocess :ref => 'final_stage'
  #     end
  #     sequence do
  #       participant :ref => 'controller'
  #       set 'v:go_on' => 'yes'
  #     end
  #   end
  #
  # == :test
  #
  # Most of the example process definitions until now were placing the condition
  # directly after the expression name itself. In an XML process definition or
  # if you prefer it this way, you can use the :test attribute to formulate the
  # condition :
  #
  #   <once test="${v:ready}">
  #     <participant ref="role_publisher" />
  #   </once>
  #
  # In a Ruby process definition :
  #
  #   once :test => '${v:ready}' do
  #     participant :ref => 'role_publisher'
  #   end
  #
  #
  # == :frequency
  #
  # As said, the default 'check' frequency is 10 seconds. This can be changed
  # by using the :frequency (or :freq) attribute.
  #
  #   sequence do
  #     participant 'logistic_unit'
  #     once '${v:/delivery_ok}', :frequency => '2d'
  #       # block until delivery is OK (another branch of the process probably)
  #       # check every two days
  #     participant 'accounting_unit'
  #   end
  #
  #
  # == :frequency and cron notation
  #
  # It's OK to pass a 'cron string' to the :frequency attribute.
  #
  #   once '${v:delivery_complete}', :freq => '5 0 * * *'
  #     # this 'once' will check its condition once per day, five minutes
  #     # after midnight
  #
  # See "man 5 crontab" on your favourite unix system for the details of
  # the 'cron string', but please note that ruote (thanks to the
  # rufus-scheduler (http://rufus.rubyforge.org/rufus-scheduler) accepts
  # seconds as well.
  #
  #
  # == the :timeout attribute common to all expressions
  #
  # Don't forget that this expression, like all the other expressions accepts
  # the :timeout attribute. It's perhaps better to use :timeout when there is
  # a child expression, so that the child won't get 'triggered' in case of
  # timeout. When there is no child expression and the 'once' behaves in a
  # 'blocking way', a timeout will unblock, as if the condition became true.
  #
  #
  # == ${ruby:'hello'}
  #
  # Remember that, if the engine's 'ruby_eval_allowed' is set to true, the
  # condition may contain Ruby code.
  #
  #   once '${r:"hell" + "o"} == hello'
  #
  # This Ruby code is checked before hand against malicious code, but beware...
  #
  #
  # == aliases
  #
  # 'once', '_when' and 'as_soon_as' are three different names for this
  # expression.
  #
  class OnceExpression < FlowExpression

    names :once, :when, :as_soon_as

    def apply

      h.frequency = attribute(:frequency) || attribute(:freq) || '10s'
      h.triggered = false

      reply(h.applied_workitem)
    end

    def reply(workitem)

      return reply_to_parent(workitem) if h.triggered

      t = attribute(:test) || attribute_text

      if Condition.true?(t)

        h.triggered = true

        @context.storage.delete_schedule(h.schedule_id)
          # especially for a cron...

        if tree_children[0] # trigger first child

          apply_child(0, workitem)

        else # blocking case

          reply_to_parent(workitem)
        end

      else

        reschedule
      end
    end

    protected

    def reschedule

      h.schedule_id = @context.storage.put_schedule(
        'cron',
        h.fei,
        h.frequency,
        'action' => 'reply',
        'fei' => h.fei,
        'workitem' => h.applied_workitem)

      @context.storage.delete_schedule(h.schedule_id) if try_persist
        #
        # if the persist failed, immediately unschedule
        # the just scheduled job
        #
        # this is meant to cope with cases where one worker reschedules
        # while another just cancelled
    end
  end
end

