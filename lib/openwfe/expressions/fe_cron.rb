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


module OpenWFE

  #
  # Scheduling subprocesses for repeating execution
  #
  #   <cron tab="0 9-17 * * mon-fri">
  #     <send-reminder/>
  #   </cron>
  #
  # In this short process definition snippet, the subprocess "send-reminder"
  # will get triggered once per hour (minute 0) from 0900 to 1700 and
  # this, from monday to friday.
  #
  # It's possible to specify 'every' instead of 'tab' :
  #
  #   cron :every => "10m3s" do
  #     send_reminder
  #   end
  #
  # The subprocess 'send_reminder' will thus be triggered every ten minutes
  # and three seconds.
  #
  # The cron expression never replies [to its parent expression].
  # The classical usage for it is with a concurrence set to expect only
  # one reply :
  #
  #   concurrence :count => 1 do
  #     participant :toto
  #     cron :every => "10m" do
  #       send_reminder_email :target => "toto@headlost.org.uk"
  #     end
  #   end
  #
  # The sub process 'send_reminder_email' will thus be triggered every 10
  # minutes while concurrence is waiting for the answer (reply) of the
  # participant :toto.
  #
  # If the process instance containing a cron is paused, the cron won't get
  # triggered until the process is resumed.
  #
  # === scheduler tags
  #
  # Scheduler tags can be set like this :
  #
  #   cron :every => "10s", :scheduler_tags => "pesky_job" do
  #     participant :ref => "toto"
  #   end
  #
  # This is an advanced feature that most users won't need.
  #
  class CronExpression < TimeExpression

    names :cron

    #
    # The cron 'tab', something like "0 9-17 * * mon-fri"
    #
    attr_accessor :tab

    #
    # If 'tab' is not, then 'every' should, the expression will trigger
    # at the frequency specified here (like for example "10m3s).
    #
    attr_accessor :every

    #
    # Keeping track of how many times the cron fired.
    #
    attr_accessor :counter


    def apply (workitem)

      return reply_to_parent(workitem) if has_no_expression_child

      @counter = -1

      @applied_workitem = workitem.dup
      @applied_workitem.flow_expression_id = nil

      @tab = lookup_attribute(:tab, workitem)
      @every = lookup_attribute(:every, workitem)

      determine_scheduler_tags

      #
      # schedule self

      reschedule(get_scheduler)
    end

    def reply (workitem)
      # discard silently...
    end

    #
    # This is the method called each time the scheduler triggers
    # this cron. The contained segment of process will get
    # executed.
    #
    def trigger (params)

      return if paused?

      ldebug { "trigger() cron : #{@fei.to_debug_s}" }

      #@raw_child.application_context = @application_context
        # done in expool.tlaunch_child()

      begin

        @counter += 1
        store_itself
          #
          # note : one variant would be to give Time.now.to_f as a sub_id...
          # then no need to store...
          #
          # but it's good to have a counter to keep track of the number of
          # executions

        child_fei = get_expression_pool.tlaunch_child(
          self,
          first_expression_child,
          @counter,
          @applied_workitem.dup,
          :register_child => false)
            #
            # register_child is set to false, cron doesn't keep
            # track of its spawned children

      rescue

        lerror do
          "trigger() cron caught exception\n#{OpenWFE::exception_to_s($!)}"
        end
      end
    end

    #
    # This method is called at the first schedule of this expression
    # or each time the engine is restarted and this expression has
    # to be rescheduled.
    #
    def reschedule (scheduler)

      @scheduler_job_id = "#{@fei.wfid}__#{@scheduler_job_id}"

      method, arg0 = if @tab
        [ :schedule, @tab ]
      else
        [ :schedule_every, @every ]
      end

      get_scheduler.send(
        method,
        arg0,
        {
          :schedulable => self,
          :job_id => @scheduler_job_id,
          :tags => @scheduler_tags })

      #ldebug { "reschedule() name is   '#{@name}'" }
      ldebug { "reschedule() job id is '#{@scheduler_job_id}'" }
    end
  end

end

