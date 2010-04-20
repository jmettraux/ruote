#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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

require 'ruote/part/listener'


module Ruote

  #
  # Provides methods for 'local' participants.
  #
  # Assumes the class that includes this module has a #context method
  # that points to the worker or engine ruote context.
  #
  # It's "local" because it has access to the ruote storage.
  #
  module LocalParticipant

    include Listener
      # the reply_to_engine method is there

    # WARNING : this method is only for 'stateless' participants, ie
    # participants that are registered in the engine by passing their class
    # and a set of options, like in
    #
    #   engine.register_participant 'alpha', MyParticipant, 'info' => 'none'
    #
    # This reject method replaces the workitem in the [internal] message queue
    # of the ruote engine (since it's a local participant, it has access to
    # the storage and it's thus easy).
    # The idea is that another worker will pick up the workitem and
    # do the participant dispatching.
    #
    # This is an advanced technique. It was requested by people who
    # want to have multiple workers and have only certain worker/participants
    # do the handling.
    # Using reject is not the best method, it's probably better to implement
    # this by re-opening the Ruote::Worker class and changing the
    # cannot_handle(msg) method.
    #
    # reject could be useful anyway, not sure now, but one could imagine
    # scenarii where some participants reject workitems temporarily (while
    # the same participant on another worker would accept it).
    #
    # Well, here it is, use with care.
    #
    def reject (workitem)

      @context.storage.put_msg(
        'dispatch',
        'fei' => workitem.h.fei,
        'workitem' => workitem.h,
        'participant_name' => workitem.participant_name,
        'rejected' => true)
    end
  end
end

