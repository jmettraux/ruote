#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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


require 'ruote/exp/flowexpression'


module Ruote::Exp

  #
  # The 'when' expression verifies if a condition is true, if not it will
  # block and after 10 seconds it will check again.
  # If true, it will resume or it will execute its child expression (before
  # resuming).
  #
  #   concurrence do
  #
  #     _when '${v:/invoice_status} == emitted' do
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
  # Note the '_when' since 'when' is a Ruby keyword :-(
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
  #     _when '${v:ready_for_second_stage}'
  #     second_stage
  #   end
  #
  # When there is a child expression, it will get triggered when the condition
  # realizes. Only 1 child expression is accepted, there is no implicit
  # 'sequence'.
  #
  #   concurrence do
  #     _when :test => '${v:go_on} == yes' do
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
  #   <when test="${v:ready}">
  #     <participant ref="role_publisher" />
  #   </when>
  #
  # In a Ruby process definition :
  #
  #   _when :test => '${v:ready}' do
  #     participant :ref => 'role_publisher'
  #   end
  #
  #
  # == :frequency
  #
  # As said, the default 'check' frequency is 10 seconds. This can be changed
  # by using the :frequency (or :freq) attribute.
  #
  #    sequence do
  #
  #      participant 'logistic_unit'
  #
  #      _when '${v:/delivery_ok}', :frequency => '2d'
  #        # block until delivery is OK (another branch of the process probably)
  #        # check every two days
  #
  #      participant 'accounting_unit'
  #    end
  #
  #
  # == :frequency and cron notation
  #
  # It's OK to pass a 'cron string' to the :frequency attribute.
  #
  #   _when '${v:delivery_complete}', :freq => '5 0 * * *'
  #     # this 'when' will check its condition once per day, five minutes
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
  # timeout. When there is no child expression and the 'when' behaves in a
  # 'blocking way', a timeout will unblock, as if the condition became true.
  #
  #
  # == ${ruby:'hello'}
  #
  # Remember that, if the engine's :ruby_eval_allowed is set to true, the
  # condition may contain Ruby code.
  #
  #   _when '${r:"hell" + "o"} == hello'
  #
  # This Ruby code is checked before hand against malicious code, but beware...
  #
  class WhenExpression < FlowExpression

    names :when, :as_soon_as

    def apply

      @frequency = attribute(:frequency) || attribute(:freq) || '10s'
      @triggered = false

      reply(@applied_workitem)
    end

    def reply (workitem)

      return reply_to_parent(workitem) if @triggered

      t = attribute_text(:test) || attribute_text

      if Condition.true?(t)

        @triggered = true

        scheduler.unschedule(@job_id)
          # especially for a cron...

        if tree_children[0]
          #
          # trigger first child
          #
          apply_child(0, workitem)
        else
          #
          # blocking case
          #
          reply_to_parent(workitem)
        end
      else

        reschedule
      end
    end

    def cancel (flavour)

      scheduler.unschedule(@job_id)
      reply_to_parent(@applied_workitem)
    end

    # Note : this method has to be public.
    #
    def reschedule

      @job_id = if @frequency.match(/. ./)

        return if @job_id && scheduler.jobs[@job_id]
          # don't reschedule if not necessary

        scheduler.cron(@frequency, @fei, :reply).job_id
      else

        scheduler.in(@frequency, @fei, :reply).job_id
      end

      persist
    end
  end
end

