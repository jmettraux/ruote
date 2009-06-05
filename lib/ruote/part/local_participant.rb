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


require 'ruote/part/local_participant'


module Ruote

  module LocalParticipant

    def reply_to_engine (workitem)

      engine.reply(workitem)
    end
  end

  module JoinableParticipant

    def join

      #p [ :joiner, Thread.current ]

      return if size > 0

      @waiting = Thread.current

      if lonely_thread? # covers EM flavour as well
        sleep 0.350
      else
        Thread.stop
      end
    end

    protected

    def notify

      return unless @waiting

      #p [ :notifier, Thread.current ]
      #p [ :notified, @waiting ]

      @waiting.wakeup
      @waiting = nil
    end

    def lonely_thread?
      others = Thread.list - [ Thread.current ]
      (others.select { |t| t.status == 'run' }.size == 0)
    end
  end
end

