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


module OpenWFE

  #
  # Since Ruote 0.9.20, 'sleep' got merged into 'wait' (according to Kenneth
  # 'wait' sounds less lazy than 'sleep')
  #
  # The expression names are interchangeable.
  #
  # = wait
  #
  # The 'wait' expression simply blocks/waits until the given condition
  # evaluates to true.
  # This expression accepts a timeout (else it will block ad eternam).
  #
  #   sequence do
  #     wait :until => "${done} == true"
  #     participant :toto
  #   end
  #
  # Participant 'toto' will receive a workitem after the variable 'done' is
  # set to true (somewhere else in the process definition).
  #
  #   sequence do
  #     wait :runtil => "Time.new.to_i % 7 == 0"
  #     participant :toto
  #   end
  #
  # Participant 'toto' will receive a workitem after a certain condition
  # expressed directly in Ruby evaluates to true.
  #
  # 'wait' is different than 'when' : when it times out (if a timeout is set,
  # the wait ceases and the flow resumes. On a timeout, 'when' will not
  # execute its nested 'consequence' child.
  #
  #
  # = sleep
  #
  # The 'sleep' expression expects one attribute, either 'for', either
  # 'until'.
  #
  #   <sequence>
  #     <sleep for="10m12s" />
  #     <participant ref="alpha" />
  #   </sequence>
  #
  # will wait for 10 minutes and 12 seconds before sending a workitem
  # to participant 'alpha'.
  #
  # In a Ruby process definition, that might look like :
  #
  #   _sleep :for => "3m"
  #   _sleep "3m"
  #     #
  #     # both meaning 'sleep for 3 minutes'
  #
  #   _sleep :until => "Mon Dec 03 10:41:58 +0900 2007"
  #     #
  #     # sleep until the given point in time
  #
  # If the 'until' attribute points to a time in the past, the sleep
  # expression will simply let the process resume.
  #
  # _sleep needs to be used instead of 'sleep', so it doesn't conflict
  # with Ruby's builtin sleep method.
  #
  # === scheduler tags
  #
  # Scheduler tags can be set like this :
  #
  #   _sleep "10y", :scheduler_tags => "la_belle_au_bois_dormant"
  #
  # This is an advanced feature (that most users won't need).
  #
  # === sleeping for 8 hours
  #
  # If you tell a process instance to sleep for 8 hours, then shutdown the
  # engine for 4 hours, at restart, it will sleep until the 8 hours have
  # passed (so it will sleep for four hours).
  #
  # If the engine is stopped for more than eight hours, at restart, the process
  # instance will immediately resume (sleep overdone).
  #
  class WaitExpression < WaitingExpression

    names :wait, :sleep
    conditions :until

    attr_accessor :until

    def apply (workitem)

      #
      # is it a sleep ?

      sfor = lookup_string_attribute(:for, workitem)
      suntil = lookup_string_attribute(:until, workitem)

      sfor = fetch_text_content(workitem) if sfor == nil and suntil == nil

      @until = if suntil
        Rufus.to_ruby_time(suntil) rescue nil
      elsif sfor
        (Time.new.to_f + Rufus::parse_time_string(sfor)) rescue nil
      else
        nil # just to be sure
      end

      @until ? apply_sleep(workitem) : super(workitem)
    end

    def reschedule (scheduler)

      @until ? reschedule_sleep : super(scheduler)
    end

    def trigger (params={})

      @until ? reply_to_parent(@applied_workitem) : super(params)
    end

    protected

    def apply_sleep (workitem) #:nodoc#

      @applied_workitem = workitem.dup

      determine_scheduler_tags

      reschedule(get_scheduler)
    end

    def reschedule_sleep #:nodoc#

      ldebug do
        "[re]schedule() " +
        "will sleep until '#{@until}' " +
        "(#{Rufus::to_iso8601_date(@until)})"
      end

      @scheduler_job_id = "sleep_#{self.fei.to_s}"

      store_itself

      get_scheduler.schedule_at(
        @until,
        {
          :schedulable => self,
          :job_id => @scheduler_job_id,
          :tags => @scheduler_tags })

      ldebug do
        "[re]schedule() @scheduler_job_id is '#{@scheduler_job_id}' "+
        " (scheduler #{get_scheduler.object_id})"
      end
    end
  end
end

