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


require 'rufus/otime'


module OpenWFE

  #
  # The timeout behaviour is implemented here, making it easy
  # to mix it in into ParticipantExpression and WhenExpression.
  #
  module TimeoutMixin
    include Rufus::Schedulable

    attr_accessor :timeout_at
    attr_accessor :timeout_job_id

    #
    # Looks for the "timeout" attribute in its process definition
    # and then sets the @timeout_at field (if there is a timeout).
    #
    def determine_timeout (workitem, timeout_attname=:timeout)

      #@timeout_at = nil
      #@timeout_job_id = nil

      s_timeout = lookup_attribute(timeout_attname, @applied_workitem)
      return unless s_timeout

      begin
        timeout = Rufus::parse_time_string(s_timeout)
        @timeout_at = Time.new.to_f + timeout
      rescue
        @timeout_at = Time.parse(s_timeout)
        #If the user specifies a time of day (16:00), then we schedule for when that time next occurs whether today or tomorrow (not the past)
        @timeout_at += 86400 if @timeout_at < Time.now && s_timeout =~ /\d{1,2}:\d{1,2}/
      end

      stamp_workitem(workitem, s_timeout)
    end

    #
    # Providing a default reschedule() implementation for the expressions
    # that use this mixin.
    # This default implementation just reschedules the timeout.
    #
    def reschedule (scheduler)
      to_reschedule(scheduler)
    end

    #
    # Combines a call to determine_timeout and to reschedule.
    #
    def schedule_timeout (workitem, timeout_attname=:timeout)

      determine_timeout(workitem, timeout_attname)
      to_reschedule(get_scheduler)
    end

    #--
    # Overrides the parent method to make sure a potential
    # timeout schedules gets removed.
    #
    # Well... Leave that to classes that mix this in...
    # No method override in a mixin...
    #
    #def reply_to_parent (workitem)
    #  unschedule_timeout(workitem)
    #  super(workitem)
    #end
    #++

    #
    # Places a "__timed_out__" field in the workitem.
    #
    def set_timedout_flag (workitem)

      workitem.attributes['__timed_out__'] = 'true'
    end

    #
    # Removes any "__timed_out__" field in the workitem.
    #
    def remove_timedout_flag (workitem)

      workitem.attributes.delete('__timed_out__')
    end

    protected

    def stamp_workitem (wi, timeout)

      return unless wi

      key = "#{@fei.wfid}__#{@fei.expid}"

      stamp = [
        self.class.name, @fei.expname, Time.now.to_f, timeout, @timeout_at
      ]

      (wi.attributes['__timeouts__'] ||= {})[key] = stamp
    end

    def unstamp_workitem (wi)

      return unless wi

      stamps = wi.attributes['__timeouts__']
      return unless stamps

      stamps.delete("#{@fei.wfid}__#{@fei.expid}")
    end

    #
    # prefixed with "to_" for easy mix in
    #
    def to_reschedule (scheduler)

      #return if @timeout_job_id
        #
        # already rescheduled

      return unless @timeout_at
        #
        # no need for a timeout

      @timeout_job_id = "timeout_#{self.fei.to_s}"

      scheduler.schedule_at(
        @timeout_at,
        { :schedulable => self,
          :job_id => @timeout_job_id,
          :do_timeout! => true,
          :tags => [ "timeout", self.class.name ] })

      ldebug do
        "to_reschedule() will timeout at " +
        "#{Rufus::to_iso8601_date(@timeout_at)}" +
        " @timeout_job_id is #{@timeout_job_id}" +
        " (oid #{object_id})"
      end

      #store_itself()
        #
        # done in the including expression
    end

    #
    # Unschedules the timeout
    #
    def unschedule_timeout (workitem)

      #ldebug do
      #  "unschedule_timeout() " +
      #  "@timeout_job_id is #{@timeout_job_id}" +
      #  " (oid #{object_id})"
      #end

      return unless @timeout_job_id

      get_scheduler.unschedule(@timeout_job_id)
      unstamp_workitem(workitem)
    end
  end

end

