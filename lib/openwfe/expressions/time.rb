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

require 'rufus/otime'
require 'openwfe/expressions/timeout'


module OpenWFE

  #
  # A parent class for CronExpression and SleepExpression, is never
  # used directly.
  # It contains a simple get_scheduler() method simplifying the scheduler
  # localization for <sleep/> and <cron/>.
  #
  class TimeExpression < FlowExpression
    include Rufus::Schedulable

    #
    # The workitem received at apply time
    #
    attr_accessor :applied_workitem

    #
    # The job_id in the scheduler for this expression
    #
    attr_accessor :scheduler_job_id

    #
    # The tags (if any) for the job in the scheduler
    #
    attr_accessor :scheduler_tags

    #
    # Makes sure to cancel any scheduler job associated with this
    # expression
    #
    def cancel

      unschedule

      super()

      @applied_workitem
    end

    #
    # If the expression has been scheduled, a call to this method
    # will make sure it's unscheduled (removed from the scheduler).
    #
    def unschedule

      ldebug { "unschedule() @scheduler_job_id is #{@scheduler_job_id}" }

      sleep get_scheduler.precision + 0.001
        #
        # make sure not to unschedule before the actual scheduling
        # got done.

      get_scheduler.unschedule(@scheduler_job_id) \
        if @scheduler_job_id
    end

    protected

      #
      # looks up potential scheduler tags in the expression
      # attributes
      #
      def determine_scheduler_tags

        @scheduler_tags = lookup_array_attribute(
          :scheduler_tags, @applied_workitem) || []

        @scheduler_tags << self.class.name

        @scheduler_tags << fei.to_short_s
        @scheduler_tags << fei.parent_wfid
      end
  end

  #
  # A parent class for WhenExpression and WaitExpression.
  #
  # All the code for managing waiting for something to occur is
  # concentrated here.
  #
  class WaitingExpression < TimeExpression
    include ConditionMixin
    include TimeoutMixin

    attr_accessor :frequency

    #uses_template

    #
    # By default, classes extending this class do poll for their
    # condition every 10 seconds.
    #
    DEFAULT_FREQUENCY = "10s"

    #
    # Don't go under 300 milliseconds.
    #
    MIN_FREQUENCY = 0.300

    #
    # Classes extending this WaitingExpression have a 'conditions' class
    # method (like 'attr_accessor').
    #
    def self.conditions (*attnames)

      attnames = attnames.collect do |n|
        n.to_s.to_sym
      end
      meta_def :condition_attributes do
        attnames
      end
    end

    def apply (workitem)

      remove_timedout_flag workitem

      @applied_workitem = workitem.dup

      @frequency = lookup_attribute(
        :frequency, workitem, :default => DEFAULT_FREQUENCY)
      @frequency = Rufus::parse_time_string(
        @frequency)
      @frequency = MIN_FREQUENCY \
        if @frequency < MIN_FREQUENCY

      determine_timeout(workitem)
      determine_scheduler_tags

      condition_attribute = determine_condition_attribute(
        self.class.condition_attributes)

      #
      # register consequence

      consequence = condition_attribute ?
        raw_children[0] : raw_children[1]

      consequence = nil if consequence.is_a?(String)

      get_expression_pool.tprepare_child(
        self,
        consequence,
        0,
        true, # please register child
        nil   # no vars
      ) if consequence

      #
      # go east...

      store_itself

      trigger
    end

    def reply (workitem)

      result = workitem.get_result

      if result
        apply_consequence workitem
      else
        reschedule get_scheduler
      end
    end

    #
    # Cancels this expression (takes care of unscheduling a timeout
    # if there is one).
    #
    def cancel

      unschedule_timeout(nil)
      super()
    end

    def trigger (params={})

      ldebug { "trigger() #{@fei.to_debug_s} params : #{params.inspect}" }

      if params[:do_timeout!]
        #
        # do timeout...
        #
        set_timedout_flag(@applied_workitem)
        reply_to_parent(@applied_workitem)
        return
      end

      @scheduler_job_id = nil

      evaluate_condition
    end

    def reschedule (scheduler)

      @scheduler_job_id = "waiting_#{fei.to_s}"

      scheduler.schedule_in(
        @frequency,
        {
          :schedulable => self,
          :job_id => @scheduler_job_id,
          :tags => @scheduler_tags })

      ldebug { "reschedule() @scheduler_job_id is #{@scheduler_job_id}" }

      to_reschedule scheduler
    end

    def reply_to_parent (workitem)

      unschedule
      unschedule_timeout(workitem)

      super(workitem)
    end

    protected

      #
      # The code for the condition evalution is here.
      #
      # This method is overriden by the WhenExpression.
      #
      def evaluate_condition

        condition_attribute = determine_condition_attribute(
          self.class.condition_attributes)

        if condition_attribute

          c = eval_condition condition_attribute, @applied_workitem

          do_reply c
          return
        end

        # else, condition is nested as a child

        #if @children.size < 1
        if raw_children.size < 1
          #
          # no condition attribute and no child attribute,
          # simply reply to parent
          #
          reply_to_parent @applied_workitem
          return
        end

        # trigger the first child (the consequence child)

        get_expression_pool.tlaunch_child(
          self,
          raw_children.first,
          (Time.new.to_f * 1000).to_i,
          @applied_workitem.dup,
          false) # not registering as a child
      end

      #
      # Used when replying to self after an attribute condition
      # got evaluated
      #
      def do_reply (result)

        @applied_workitem.set_result result
        reply @applied_workitem
      end

      #
      # This method is overriden by WhenExpression. WaitExpression
      # doesn't override it.
      # This default implementation simply directly replies to
      # the parent expression.
      #
      def apply_consequence (workitem)

        reply_to_parent workitem
      end
  end

end

