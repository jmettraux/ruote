#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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

  #
  # A participant that simply replies immediately to the engine.
  #
  # For testing purposes, but could be useful when used in conjunction with
  # 'listen'.
  #
  class NoOpParticipant < Participant

    #
    # No operation : simply replies immediately.
    #
    def on_workitem

      reply
    end
  end

  #
  # A /dev/null participant, simply discards the workitems it receives,
  # without doing anything.
  #
  # For testing purposes only.
  #
  class NullParticipant < Participant

    # Does nothing, discards the workitem it receives.
    #
    def on_workitem
    end
  end

  #
  # This participant removes itself (well, the corresponding participant
  # expression) and never replies.
  #
  # Used to simulate lost replies.
  #
  class LostReplyParticipant < Participant

    def on_workitem

      r = context.storage.delete(fexp.h)
      raise "failed to remove self" if r != nil

      # do not reply.
    end

    def do_not_thread; true; end
  end
end

