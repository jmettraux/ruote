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


require 'ruote/util/tree'
#require 'ruote/log/logger'


module Ruote

  class TestLogger

    NOTEWORTHY = %w[ terminated cancelled killed dispatched ]

    def initialize (context)

      @context = context

      if @context.respond_to?(:worker)
        #
        # this is a worker context, DO log
        #
        @context.worker.subscribe(:all, :all, self)
      else
        #
        # this is not a worker context, DO NOT log, but be ready to
        # be queried
        #
      end

      @noteworthy = []
      @waiting = nil

      # NOTE
      # in case of troubles, why not have the wait_for has an event ?
    end

    def notify (event)

      @context.storage.put(event.merge('type' => 'archived_task'))

      @noteworthy << event if NOTEWORTHY.include?(event['action'])

      check_waiting
    end

    def wait_for (interest)

      @waiting = [ Thread.current, interest ]

      check_waiting

      Thread.stop if @waiting
    end

    protected

    def check_waiting

      return unless @waiting

      thread, interest = @waiting

      over = @noteworthy.find do |event|

        if interest.is_a?(Symbol) # participant

          (event['action'] == 'dispatched' &&
           event['participant_name'] == interest.to_s)

        else # wfid

          event['wfid'] == interest
        end
      end

      if over
        @waiting = nil
        thread.wakeup
      end
    end
  end
end

