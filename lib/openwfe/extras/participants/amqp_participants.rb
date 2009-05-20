#--
# Copyright (c) 2008-2009, Kenneth Kalmer, opensourcery.co.za
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
# Made in Africa. Kenneth Kalmer of opensourcery.co.za
#++

require 'yaml'
require 'mq'
require 'openwfe/util/xml'

module OpenWFE
  module Extras

    # = AMQP Participants
    #
    # The AMQPParticipant allows you to send workitems (serialized as
    # JSON) or messages to any AMQP queues right from the process
    # definition. When combined with the AMQPListener you can easily
    # leverage an extremely powerful local/remote participant
    # combinations.
    #
    # By default the participant relies on the presence of an AMQP
    # listener. Workitems are sent and no replies are given to the
    # engine. The participant can be configured to reply to the engine
    # immediately after queueing a message, see the usage section below.
    #
    # == Configuration
    #
    # AMQP configuration is handled by directly manipulating the
    # values of the +AMQP.settings+ hash, as provided by the AMQP
    # gem. No AMQP defaults are set by the participant.
    #
    # The participant requires version 0.6.1 or later of the amqp gem.
    #
    # == Usage
    #
    # Currently it's possible to send either workitems or messages
    # directly to a specific queue, and have the engine wait for
    # replies on another queue (see AMQPListener).
    #
    # Setting up the participant
    #
    #   engine.register_participant(
    #     :amqp, OpenWFE::Extras::AMQPParticipant )
    #
    # Setup a participant that always replies to the engine
    #
    #   engine.register_participant(
    #     :amp, OpenWFE::Extras::AMQPParticipant.new(:reply_by_default => true ) )
    #
    # Sending a message example
    #
    #   class AmqpMessageExample0 < OpenWFE::ProcessDefinition
    #     sequence do
    #       amqp :queue => 'test', :message => 'foo'
    #     end
    #   end
    #
    # Sending a workitem
    #
    #   class AmqpWorkitemExample0 < OpenWFE::ProcessDefinition
    #     sequence do
    #       amqp :queue => 'test'
    #     end
    #   end
    #
    # Let the participant reply to the engine without involving the listener
    #
    #   class AmqpWaitExample < OpenWFE::ProcessDefinition
    #     sequence do
    #       amqp :queue => 'test', :reply_anyway => true
    #     end
    #   end
    #
    # When waiting for a reply it only makes sense to send a workitem.
    #
    # == Workitem modifications
    #
    # To ease replies, and additional workitem attribute is set:
    #
    #   'reply_queue'
    #
    # +reply_queue+ has the name of the queue where the AMQPListener
    # expects replies from remote participants
    #
    # == AMQP notes
    #
    # The participant currently only makes use of direct
    # exchanges. Possible future improvements might see use for topic
    # and fanout exchanges as well.
    #
    # The direct exchanges are always marked as durable by the
    # participant.
    #
    class AMQPParticipant
      include LocalParticipant

      # Accepts an options hash with the following keys:
      #
      # * :reply_by_default => (bool) false by default
      def initialize( options = {} )
        ensure_reactor!

        @options = {
          :reply_by_default => false
        }.merge( options )
      end

      # Process the workitem at hand. By default the workitem will be
      # published to the direct exchange specified in the +queue+
      # workitem parameter. You can specify a +message+ workitem
      # parameter to have that sent instead of the workitem.
      #
      # To force the participant to reply to the engine, set the
      # +reply_anyway+ workitem parameter.
      def consume( workitem )
        ldebug { "consuming workitem" }
        ensure_reactor!

        if target_queue = workitem.params['queue']

          q = MQ.queue( target_queue, :durable => true )

          # Message or workitem?
          if message = ( workitem.attributes['message'] || workitem.params['message'] )
            ldebug { "sending message to queue: #{target_queue}" }
            q.publish( message )

          else
            ldebug { "sending workitem to queue: #{target_queue}" }

            q.publish( encode_workitem( workitem ) )
          end
        else
          lerror { "no queue in workitem params!" }
        end

        if @options[:reply_by_default] || workitem.params['reply-anyway'] == true
          reply_to_engine( workitem )
        end

        ldebug { "done" }
      end

      def stop
        linfo { "Stopping..."  }

        AMQP.stop { EM.stop } #if EM.reactor_running? }
        @em_thread.join if @em_thread
      end

      protected

      # Encode (and extend) the workitem as JSON
      def encode_workitem( wi )
        wi.attributes['reply_queue'] = AMQPListener.queue
        wi.to_h.to_json
      end

      def ensure_reactor!
        @em_thread = Thread.new { EM.run } unless EM.reactor_running?
      end
    end
  end
end
