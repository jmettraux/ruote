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


module Ruote

  class WaitExpression < FlowExpression

    names :wait, :sleep

    def apply

      sfor = attribute(:for) || attribute_text
      suntil = attribute(:until)

      @until = if suntil
        Rufus.to_ruby_time(suntil)# rescue nil
      elsif sfor
        (Time.now.to_f + Rufus.parse_time_string(sfor))# rescue nil
      else
        nil
      end

      if @until
        schedule
      else
        reply_to_parent(@applied_workitem)
      end
    end

    #--
    # no need to override, simply reply to parent expression.
    #def reply (workitem)
    #end
    #++

    def cancel

      unschedule
      reply_to_parent(@applied_workitem)
    end

    protected

    def reschedule

      @job_id = scheduler.at(@until, @fei, :reply).job_id
      persist
    end

    def schedule

      reschedule
      wqueue.emit(:expressions, :schedule_at, :until => @until)
    end

    def unschedule

      scheduler.unschedule(@job_id)
    end
  end
end

