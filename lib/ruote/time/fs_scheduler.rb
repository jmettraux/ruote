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


require 'ruote/time/scheduler'


module Ruote

  class JobQueue < Rufus::Scheduler::JobQueue

    attr_reader :bucket
    attr_accessor :scheduler

    def initialize (fpath)

      #@mutex = Mutex.new
        # no need for thread synchro, the workqueue does it for us

      @bucket = Bucket.new(fpath)
      @bucket.save([])
    end

    def trigger_matching_jobs

      operate(true) do |jobs|
        #
        # true to skip when locked by someone else

        now = Time.now

        while job = job_to_trigger(jobs, now)
          job.trigger
        end
      end
    end

    def << (job)

      operate do |jobs|
        delete(jobs, job.job_id)
        jobs << job
        jobs.sort! { |j0, j1| j0.at <=> j1.at }
      end
    end

    def unschedule (job_id)

      operate { |jobs| delete(jobs, job_id) }
    end

    def size

      operate { |jobs| jobs.size }
    end

    def to_h

      operate { |jobs| jobs.inject({}) { |h, j| h[j.job_id] = j; h } }
    end

    protected

    def operate (skip=false, &block)

      @bucket.operate(skip) do |jobs|
        jobs.each { |j| j.scheduler = @scheduler }
        r = block.call(jobs)
        jobs.each { |j| j.scheduler = nil }
        r
      end
    end

    def job_to_trigger (jobs, now)

      if jobs.size > 0 && now.to_f >= jobs.first.at
        jobs.shift
      else
        nil
      end
    end

    def delete (jobs, job_id)

      j = jobs.find { |j| j.job_id == job_id }
      jobs.delete(j) if j
    end
  end

  class CronJobQueue < JobQueue

    def trigger_matching_jobs

      operate(true) do |jobs|

        now = Time.now

        return if now.sec == @last_cron_second
        @last_cron_second = now.sec

        jobs.each { |job| job.trigger_if_matches(now) }
      end
    end

    def << (job)

      operate(false) do |jobs|

        delete(jobs, job.job_id)
        jobs << job
      end
    end
  end

  class FsScheduler < Scheduler

    def context= (c)

      @context = c

      jq = JobQueue.new(File.join(workdir, 'at.ruote'))
      cjq = CronJobQueue.new(File.join(workdir, 'cron.ruote'))

      @scheduler = Rufus::Scheduler.start_new(
        :context => @context, :job_queue => jq, :cron_job_queue => cjq)
    end

    protected

    def reload

      # TODO : implement me !
    end
  end
end

