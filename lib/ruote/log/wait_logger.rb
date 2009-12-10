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


module Ruote

  #
  # A helper logger for quickstart examples.
  #
  class WaitLogger

    def initialize (context)

      @context = context
      @waiting = nil

      @context.worker.subscribe(:all, self) if @context.respond_to?(:worker)
    end

    def notify (msg)

      check_waiting(msg)
    end

    def wait_for (interest)

      @waiting = [ Thread.current, interest ]

      Thread.stop
    end

    protected

    def check_waiting (msg)

      return unless @waiting

      thread, interest = @waiting

      action = msg['action']

      over = if interest.is_a?(Symbol) # participant

        (action == 'dispatch' && msg['participant_name'] == interest.to_s)

      elsif interest.is_a?(Fixnum)

        interest = interest - 1
        @waiting = [ thread, interest ]

        (interest < 1)

      else # wfid

        %w[ terminated ceased error_intercepted ].include?(action) &&
        msg['wfid'] == interest
      end

      if over
        @waiting = nil
        thread.wakeup
      end
    end
  end
end

