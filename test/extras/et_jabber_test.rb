
#
# Testing Ruote (OpenWFEru)
#
# Kenneth Kalmer at opensourcery.co.za
#
# Mon Feb 16
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/extras/participants/jabber_participants'
require 'openwfe/extras/listeners/jabber_listeners'
require 'openwfe/util/json'

class EtJabberTest < Test::Unit::TestCase
  include FunctionalBase

  def setup
    @@connections ||= {}

    if @@connections.include?(:client1)
      @client1 = @@connections[:client1]
      @client2 = @@connections[:client2]
      @client1.accept_subscriptions = true
      @client2.accept_subscriptions = true
      @jid1_raw = @@connections[:jid1_raw]
      @jid2_raw = @@connections[:jid2_raw]
      @jid1 = @jid1_raw.strip.to_s
      @jid2 = @jid2_raw.strip.to_s

      super

      return true
    end

    logins = []
    begin
      logins = File.readlines(File.expand_path("~/.xmpp4r-simple-test-config")).map! { |login| login.split(" ") }
      raise StandardError unless logins.size == 2
    rescue => e
      puts "\nConfiguration Error!\n\nYou must make available two unique Jabber accounts in order for the tests to pass."
      puts "Place them in ~/.xmpp4r-simple-test-config, one per line like so:\n\n"
      puts "user1@example.com/res password"
      puts "user2@example.com/res password\n\n"
      raise e
    end

    @@connections[:client1] = Jabber::Simple.new(*logins[0])
    @@connections[:client2] = Jabber::Simple.new(*logins[1])

    @@connections[:jid1_raw] = Jabber::JID.new(logins[0][0])
    @@connections[:jid2_raw] = Jabber::JID.new(logins[1][0])

    # Force load the client and roster, just to be safe.
    @@connections[:client1].roster
    @@connections[:client2].roster

    setup
  end

  def test_jabber_participant

    pdef = <<-EOF
    class JabberParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        jabber
        echo 'done.'
      end

      set :field => 'target_jid', :value => "#{@jid2}"
    end
    EOF

    jabberp = @engine.register_participant(
      :jabber, OpenWFE::Extras::JabberParticipant.new(:connection => @client1))

    assert_equal false, @client1.subscribed_to?( @jid2 )

    assert_trace(pdef, 'done.')

    messages = []

    begin
      Timeout::timeout(20) {
        loop do
          messages = @client2.received_messages
          break unless messages.empty?
          sleep 1
        end
      }
    rescue Timeout::Error
      flunk "timeout waiting for messages"
    end

    assert_equal @jid1, messages.first.from.strip.to_s
    assert_match /^\{.*\}$/, messages.first.body # JSON message by default

    # roster entries must be made
    assert @client1.subscribed_to?( @jid2 )
  end

  def test_jabber_participant_message
    pdef = <<-EOF
    class JabberProcess0 < OpenWFE::ProcessDefinition
      sequence do
        jabber :message => 'Hello world'
      end

      set :field => 'target_jid', :value => "#{@jid2}"
    end
    EOF

    jabberp = @engine.register_participant(
      :jabber, OpenWFE::Extras::JabberParticipant.new(:connection => @client1))

    assert_trace( pdef, nil )

    messages = []

    begin
      Timeout::timeout(20) {
        loop do
          messages = @client2.received_messages
          break unless messages.empty?
          sleep 1
        end
      }
    rescue Timeout::Error
      flunk "timeout waiting for messages"
    end

    assert_equal 'Hello world', messages.first.body # Custom message
  end

  def test_jabber_listener
    log_level_to_debug

    pdef = <<-EOF
    class JabberParticipant0 < OpenWFE::ProcessDefinition

      sequence do
        echo '${f:foo}'
        jabber :wait_for_reply => true
        echo '${f:foo}'
      end

      set :field => 'target_jid', :value => "#{@jid2}"
      set :field => 'foo', :value => 'foo'
    end
    EOF

    jabberp = @engine.register_participant(
      :jabber, OpenWFE::Extras::JabberParticipant.new(:connection => @client1))

    @engine.register_listener(
      OpenWFE::Extras::JabberListener, :freq => '1s', :connection => @client1)

    fei = @engine.launch pdef

    messages = []

    begin
      Timeout::timeout(20) {
        loop do
          messages = @client2.received_messages
          break unless messages.empty?
          sleep 1
        end
      }
    rescue Timeout::Error
      flunk "timeout waiting for messages"
    end

    wi = OpenWFE::InFlowWorkItem.from_h( OpenWFE::Json.decode( messages.first.body ) )
    wi.attributes['foo'] = "bar"

    @client2.deliver( @jid1, OpenWFE::Json.encode( wi.to_h ) )

    wait( fei )

    assert_engine_clean( fei )

    assert_equal "foo\nbar", @tracer.to_s

    purge_engine
  end
end
