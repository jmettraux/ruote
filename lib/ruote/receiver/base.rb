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
  # The core methods for the Receiver class (sometimes a Mixin is easier
  # to integrate).
  #
  # (The engine itself includes this mixin, the LocalParticipant module
  # includes it as well).
  #
  module ReceiverMixin

    # This method pipes back a workitem into the engine, letting it resume
    # in its flow, hopefully.
    #
    def receive (workitem)

      workitem = workitem.to_h if workitem.respond_to?(:to_h)

      @context.storage.put_msg(
        'receive',
        'fei' => workitem['fei'],
        'workitem' => workitem,
        'participant_name' => workitem['participant_name'],
        'receiver' => sign)
    end

    # Given a process definitions and optional initial fields and variables,
    # launches a new process instance.
    #
    # This method is mostly used from the Ruote::Engine class (which includes
    # this mixin).
    #
    def launch (process_definition, fields={}, variables={})

      wfid = @context.wfidgen.generate

      @context.storage.put_msg(
        'launch',
        'wfid' => wfid,
        'tree' => @context.parser.parse(process_definition),
        'workitem' => { 'fields' => fields },
        'variables' => variables)

      wfid
    end

    # Wraps a call to receive(workitem)
    #
    # Not aliasing so that if someone changes the receive implementation,
    # reply is affected as well.
    #
    def reply (workitem)

      receive (workitem)
    end

    # Wraps a call to receive(workitem)
    #
    # Not aliasing so that if someone changes the receive implementation,
    # reply_to_engine is affected as well.
    #
    def reply_to_engine (workitem)

      receive (workitem)
    end

    # A receiver signs a workitem when it comes back.
    #
    # Not used much as of now.
    #
    def sign

      self.class.to_s
    end

    protected

    # Convenience method, fetches the flow expression (ParticipantExpression)
    # that emitted that workitem.
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
    # To return the whole stash
    #
    #   get(fei)
    #     # => { 'colour' => 'blue' }
    #
    # put & get are useful for a participant that needs to communicate
    # between its consume and its cancel.
    #
    def get (fei, key=nil)

      fexp = Ruote::Exp::FlowExpression.fetch(@context, fei.to_h)

      stash = fexp.h['stash'] rescue {}

      key ? stash[key] : stash
    end
  end

  #
  # A receiver is meant to receive workitems and feed them back into the
  # engine (the storage actually).
  #
  class Receiver
    include ReceiverMixin

    # Accepts context, worker, engine or storage as first argument.
    #
    def initialize (cwes, options={})

      @context = cwes.context
      @options = options
    end
  end
end

