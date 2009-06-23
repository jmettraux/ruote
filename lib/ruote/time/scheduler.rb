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


# Opening the rufus-scheduler job class to deal with FlowExpressionIds
# Keeping the original options available.
#
class Rufus::Scheduler::Job

  def trigger_block

    if @block.is_a?(Ruote::FlowExpressionId)
      fexp = scheduler.options[:context][:s_expression_storage][@block]
      fexp.reply(fexp.applied_workitem)
      #
      # TODO : what about timeouts and cancel ?
      #
    elsif @block.respond_to?(:call)
      @block.call(self)
    else
      @block.trigger(@params.merge(:job => self))
    end
  end
end


module Ruote

  class Scheduler

    include EngineContext

    def context= (c)

      @context = c

      @scheduler = Rufus::Scheduler.start_new(:context => @context)
        #:job_queue => {}, :cron_job_queue => [])
    end

    def stop

      @scheduler.stop
    end

    def at (t, fei)

      @scheduler.at(t, :schedulable => fei)
    end
  end
end

