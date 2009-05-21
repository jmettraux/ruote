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

require 'openwfe/util/json'
require 'openwfe/service'
require 'openwfe/listeners/listener'

module OpenWFE
  module Extras

    #
    # = AMQP Listeners
    #
    # Used in conjunction with the AMQPParticipant, the AMQPListener
    # subscribes to a specific direct exchange and monitors for
    # incoming workitems. It expects workitems to arrive serialized as
    # JSON (prefered), XML or YAML.
    #
    # == Configuration
    #
    # AMQP configuration is handled by directly manipulating the values of
    # the +AMQP.settings+ hash, as provided by the AMQP gem. No
    # defaults are set by the participant. The only +option+ parsed by
    # the initializer of the listener is the +queue+ key (Hash
    # expected). If no +queue+ key is set, the listener will subscribe
    # to the +ruote+ direct exchange for workitems, otherwise it will
    # subscribe to the direct exchange provided.
    #
    # The participant requires version 0.6.1 or later of the amqp gem.
    #
    # == Usage
    #
    # Register the listener with the engine:
    #
    #   engine.register_listener( OpenWFE::Extras::AMQPListener )
    #
    # The listener leverages the asynchronous nature of the amqp gem,
    # so no timers are setup when initialized.
    #
    # See the AMQPParticipany docs for information on sending
    # workitems out to remote participants, and have them send replies
    # to the correct direct exchange specified in the workitem
    # attributes.
    #
    class AMQPListener < Service
      include WorkItemListener

      # Listening queue
      @@queue = 'ruote'

      class << self

        def queue
          @@queue
        end

      end

      # Only one option is used (:queue) to determine where to listen
      # for work
      def initialize( service_name, options )

        if q = options.delete(:queue)
          @@queue = q
        end

        super( service_name, options )

        #if AMQP.connection.nil?
          @em_thread = Thread.new { EM.run }
        #end

        MQ.queue( @@queue, :durable => true ).subscribe do |message|
          workitem = decode_workitem( message )
          ldebug { "workitem from '#{@@queue}': #{workitem.inspect}" }
          handle_item( workitem )
        end
      end

      def stop
        linfo { "Stopping..." }

        AMQP.stop { EM.stop } #if EM.reactor_running? }
        @em_thread.join if @em_thread
      end

      private

      # Complicated guesswork that needs to happen here to detect the format
      def decode_workitem( msg )
        ldebug { "decoding workitem from: #{msg}" }

        # YAML?
        if msg.index('ruby/object:OpenWFE::InFlowWorkItem')
          YAML.load( msg )
        # XML?
        elsif msg =~ /^<.*>$/m
          OpenWFE::Xml.workitem_from_xml( msg )
        # Assume JSON encoded Hash
        else
          hash = ActiveSupport::JSON.decode(msg)
          OpenWFE.workitem_from_h( hash )
        end
      end
    end
  end
end
