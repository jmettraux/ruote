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


require 'rufus/scheduler'
require 'ruote/engine/context'


module Ruote

  #
  # Ruote encapsulates a pointer to a flow expression (fei) and a method
  # name in an instance of RuoteSchedulable. When the scheduler determines
  # the time has come, the flow expression is retrieved and the method is
  # called.
  #
  class RuoteSchedulable

    def initialize (fei, m)

      @fei = fei
      @method = m
    end

    def call (rufus_job)

      context = rufus_job.scheduler.options[:context]

      opts = { :fei => @fei, :scheduler => true }

      if @method == :reply

        fexp = context[:s_expression_storage][@fei]
        opts[:workitem] = fexp.applied_workitem
      end

      context[:s_workqueue].emit!(:expressions, @method, opts)
    end
  end

  #
  # Wrapping a rufus-scheduler instance, for handling all the time-related
  # things in ruote ('wait', timeouts, ...)
  #
  class Scheduler

    include EngineContext

    def context= (c)

      @context = c

      @scheduler = Rufus::Scheduler.start_new(:context => @context)

      reload
    end

    def stop

      @scheduler.stop
    end

    def at (t, fei, method)

      @scheduler.at(t, :schedulable => RuoteSchedulable.new(fei, method))
    end

    def in (t, fei, method)

      @scheduler.in(t, :schedulable => RuoteSchedulable.new(fei, method))
    end

    def unschedule (job_id)

      @scheduler.unschedule(job_id)
    end

    def jobs

      @scheduler.jobs
    end

    protected

    def reload

      exps = expstorage.find_expressions(:responding_to => :reschedule)
      exps.each { |exp| exp.reschedule }
    end
  end
end

