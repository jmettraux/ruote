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

    #uses_template

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

      return reply_to_parent(workitem) \
        if raw_children.size < 1

      @counter = 0
      #@engine_cron = false

      @applied_workitem = workitem.dup
      @applied_workitem.flow_expression_id = nil

      @tab = lookup_attribute :tab, workitem
      @every = lookup_attribute :every, workitem

      determine_scheduler_tags

      #
      # schedule self

      reschedule get_scheduler
    end

    def reply (workitem)
      # discard silently... should never get called though
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
        # done in expool.launch_template()

      begin

        #template = @raw_child
        #template, _fei = get_expression_pool.fetch @children[0]
        template = raw_children.first

        child_fei = get_expression_pool.tlaunch_child(
          self, template, @counter, @applied_workitem.dup, false)
            #
            # register_child is set to false, cron doesn't keep
            # track of its spawned children

        #
        # update count and store self

        @counter += 1

        store_itself

      rescue

        lerror do
          "trigger() cron caught exception\n"+
          OpenWFE::exception_to_s($!)
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

