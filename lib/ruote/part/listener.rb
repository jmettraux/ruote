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


module Ruote

  #
  # Listening to workitems coming [back] to the engine.
  #
  # This module contains the base methods necessary for a Listener
  # implementation.
  #
  # This module is included in the LocalParticipant one. The reply_to_engine
  # method is present in both concepts.
  #
  # Hypothetically, a listener implementation might look like :
  #
  #   require 'ruote/part/listener'
  #
  #   class MyMqListener
  #     include Ruote::Listener
  #     def initialize (queue)
  #       @queue = queue
  #     end
  #     def start_pooling
  #       while workitem = @queue.blocking_pop
  #         reply_to_engine(workitem)
  #       end
  #     end
  #   end
  #
  module Listener

    attr_accessor :context

    # Sends back the workitem to the ruote engine.
    #
    def reply_to_engine (workitem)

      # the local participant knows how to deal with the storage directly

      @context.storage.put_msg(
        'receive',
        'fei' => workitem.h.fei,
        'workitem' => workitem.h,
        'participant_name' => workitem.participant_name)
    end

    alias :reply :reply_to_engine

    protected

    # Convenience method, fetches the flow expression (ParticipantExpression)
    # that emitted that workitem.
    #
    # Used in LocalParticipant#re_apply(wi) for example.
    #
    def fetch_flow_expression (workitem)

      Ruote::Exp::FlowExpression.fetch(@context, workitem.fei.to_h)
    end

    # Stashes values in the participant expression (in the storage).
    #
    #   put(workitem.fei, 'key' => 'value', 'colour' => 'blue')
    #
    # Remember that keys/values must be serializable in JSON.
    #
    # put & get are useful for a participant that needs to communicate
    # between its consume and its cancel.
    #
    # See the thread at
    # http://groups.google.com/group/openwferu-users/t/2e6a95708c10847b for the
    # justification.
    #
    def put (fei, hash)

      fexp = Ruote::Exp::FlowExpression.fetch(@context, fei.to_h)

      (fexp.h['stash'] ||= {}).merge!(hash)

      fexp.persist_or_raise
    end

    # Fetches back a stashed value.
    #
    #   get(fei, 'colour')
    #     # => 'blue'
    #
    # put & get are useful for a participant that needs to communicate
    # between its consume and its cancel.
    #
    def get (fei, key)

      fexp = Ruote::Exp::FlowExpression.fetch(@context, fei.to_h)

      (fexp.h['stash'][key] rescue nil)
    end
  end
end

