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
  # This expression executes its children expression according to a cron
  # schedule or at a given frequency.
  #
  #   cron '15 4 * * sun' do # every sunday at 0415
  #     subprocess :ref => 'refill_the_acid_baths'
  #   end
  #
  # or
  #
  #   every '10m' do
  #     send_reminder # subprocess or participant
  #   end
  #
  # The 'tab' or 'interval' attributes may be used, this is a bit more verbose,
  # but, for instance, in XML, it is quite necessary :
  #
  #   <cron tab="15 4 * * sun">
  #     <subprocess ref="refill_the_acid_baths" />
  #   <cron>
  #
  # Triggered children subprocesses are 'forgotten'. This implies they
  # will never reply to the cron/every expression and they won't get cancelled
  # when the cron/every expression gets cancelled (the cron/every schedule
  # gets cancelled though, no new children will get cancelled).
  #
  # "man 5 crontab" in the command line of your favourite unix system might
  # help you with the semantics of the string expected by the cron expression.
  #
  #
  # == an example use case
  #
  # The cron/every expression appears often in scenarii like :
  #
  #   concurrence :count => 1 do
  #
  #     participant 'operator'
  #
  #     cron '0 9 * * 1-5' do # send a reminder every weekday at 0900
  #       notify 'operator'
  #     end
  #   end
  #
  # With a subprocess, this could become a bit more reusable :
  #
  #   Ruote.process_defintion :name => 'sample' do
  #
  #     sequence do
  #       with_reminder :participant => 'operator1'
  #       with_reminder :participant => 'operator2'
  #     end
  #
  #     define 'with_reminder' do
  #       concurrence :count => 1 do
  #         participant '${v:participant}'
  #         cron '0 9 * * 1-5' do # send a reminder every weekday at 0900
  #           notify '${v:participant}'
  #         end
  #       end
  #     end
  #   end
  #
  class CronExpression < FlowExpression

    names :cron, :every

    def apply

      h.schedule = attribute(:tab) || attribute(:interval) || attribute_text

      reschedule
    end

    def reply(workitem)

      launch_sub(
        "#{h.fei['expid']}_0",
        tree_children[0],
        :workitem => Ruote.fulldup(h.applied_workitem),
        :forget => true)

      reschedule
    end

    # Note : this method has to be public.
    #
    def reschedule

      h.schedule_id = @context.storage.put_schedule(
        'cron',
        h.fei,
        h.schedule,
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

