#
# Testing ruote AMQP participant/listener pair
#
# Kenneth Kalmer at opensourcery.co.za
#
# NOTES ON RUNNING THESE TESTS
#
# You'll need at least the amqp-0.6.1 gem and eventmachine-0.12.7 gems
# installed to be able to run the tests. If the tests fail, try
# cloning and installing the amqp gem from
# git://github.com/kennethkalmer/amqp.git while the fix is pending
#
# You'll also need access to a running AMQP broker (testing with
# RabbitMQ), and update the configuration just below the require's in
# this file
#

require File.dirname(__FILE__) + '/base'
require 'openwfe/extras/participants/amqp_participants'
require 'openwfe/extras/listeners/amqp_listeners'
require 'json'

# AMQP magic worked here
AMQP.settings[:vhost] = '/ruote-test'
AMQP.settings[:user]  = 'ruote'
AMQP.settings[:pass]  = 'ruote'

class EtAmqpTest < Test::Unit::TestCase
  include FunctionalBase

  def setup
    super

    log_level_to_debug
  end

  def stop
    super

    AMQP.stop { EM.stop }
  end

  def test_amqp_participant

    pdef = <<-EOF
    class AmqpParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        amqp :queue => 'test1', 'reply_anyway' => true
        echo 'done.'
      end
    end
    EOF

    @engine.register_participant( :amqp, OpenWFE::Extras::AMQPParticipant )

    assert_trace( pdef, 'done.' )

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test1').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 1
        end
      end
    rescue Timeout::Error
      flunk "Timeout waiting for message"
    end

    assert_match /^\{.*\}$/, @msg # JSON message by default
  end

  def test_amqp_reply_anyway_participant

    pdef = <<-EOF
    class AmqpParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        amqp :queue => 'test4'
        echo 'done.'
      end
    end
    EOF

    p = OpenWFE::Extras::AMQPParticipant.new( :reply_by_default => true )
    @engine.register_participant( :amqp, p )

    assert_trace( pdef, 'done.' )

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test4').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 1
        end
      end
    rescue Timeout::Error
      flunk "Timeout waiting for message"
    end

    assert_match /^\{.*\}$/, @msg # JSON message by default
  end

  def test_amqp_participant_message

    pdef = <<-EOF
    class AmqpParticipant1 < OpenWFE::ProcessDefinition

      sequence do
        amqp :queue => 'test2', :message => 'foo', 'reply_anyway' => true
        echo 'done.'
      end
    end
    EOF

    @engine.register_participant( :amqp, OpenWFE::Extras::AMQPParticipant )

    assert_trace( pdef, 'done.' )

    begin
      Timeout::timeout(10) do
        @msg = nil
        MQ.queue('test2').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 1
        end
      end
    rescue Timeout::Error
      flunk "Timeout waiting for message"
    end

    assert_equal 'foo', @msg
  end

  def test_amqp_listener

    pdef = <<-EOF
    class AmqpParticipant2 < OpenWFE::ProcessDefinition

      set :field => 'foo', :value => 'foo'

      sequence do
        echo '${f:foo}'
        amqp :queue => 'test3'
        echo '${f:foo}'
      end
    end
    EOF

    @engine.register_participant( :amqp, OpenWFE::Extras::AMQPParticipant )
    @engine.register_listener( OpenWFE::Extras::AMQPListener )

    fei = @engine.launch pdef

    begin
      Timeout::timeout(10) do
        msg = nil
        MQ.queue('test3').subscribe { |msg| @msg = msg }

        loop do
          break unless @msg.nil?
          sleep 1
        end
      end
    rescue Timeout::Error
      flunk "Timeout waiting for message"
    end

    wi = OpenWFE::InFlowWorkItem.from_h( JSON.parse( @msg ) )
    wi.attributes['foo'] = "bar"

    MQ.queue( wi.attributes['reply_queue'] ).publish( wi.to_h.to_json )

    wait( fei )

    assert_engine_clean( fei )

    assert_equal "foo\nbar", @tracer.to_s

    purge_engine
  end
end
