
#
# testing ruote
#
# Mon May 18 22:25:57 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtParticipantRegistrationTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_register

    #noisy

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    wait_for(1)

    msg = logger.log.last
    assert_equal 'participant_registered', msg['action']
    assert_equal 'alpha', msg['regex']

    assert_equal(
      [ 'inpa_:alpha' ],
      @engine.context.plist.instantiated_participants.collect { |e| e.first })
  end

  def test_double_registration

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end
    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    assert_equal 1, @engine.context.plist.send(:get_list)['list'].size
  end

  def test_register_and_return_participant

    pa = @engine.register_participant :alpha do |workitem|
    end

    assert_kind_of Ruote::BlockParticipant, pa
  end

  def test_participant_unregister_by_name

    #noisy

    @engine.register_participant :alpha do |workitem|
    end

    @engine.unregister_participant :alpha

    wait_for(2)
    Thread.pass

    msg = logger.log.last
    assert_equal 'participant_unregistered', msg['action']
    assert_equal '^alpha$', msg['regex']

    assert_equal 0, @engine.context.plist.instantiated_participants.size
  end

  def test_participant_unregister

    pa = @engine.register_participant :alpha do |workitem|
    end

    @engine.unregister_participant pa

    wait_for(2)

    msg = logger.log.last
    assert_equal 'participant_unregistered', msg['action']
    assert_equal '^alpha$', msg['regex']

    assert_equal 0, @engine.context.plist.instantiated_participants.size
  end

  class MyParticipant
    attr_reader :down
    def initialize
      @down = false
    end
    def shutdown
      @down = true
    end
  end

  def test_participant_shutdown

    alpha = @engine.register_participant :alpha, MyParticipant.new

    @engine.context.plist.shutdown

    assert_equal true, alpha.down
  end

  def test_participant_list_of_names

    pa = @engine.register_participant :alpha do |workitem|
    end

    assert_equal ['^alpha$'], @engine.context.plist.names
  end
end

