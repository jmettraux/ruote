
#
# Testing Ruote (OpenWFEru)
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

    sleep 0.001

    entry = logger.log.last
    assert_equal :registered, entry[1]
    assert_equal :alpha, entry.last[:regex]
    assert_equal Ruote::BlockParticipant, entry.last[:participant].class

    assert_equal [ /^alpha$/ ], @engine.plist.list.collect { |e| e.first }
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

    sleep 0.001

    entry = logger.log.last
    assert_equal(:unregistered, entry[1])
    assert_equal(/^alpha$/, entry.last[:regex])

    assert_equal 0, @engine.plist.list.size
  end

  def test_participant_unregister

    pa = @engine.register_participant :alpha do |workitem|
    end

    @engine.unregister_participant pa

    sleep 0.100

    entry = logger.log.last
    assert_equal(:unregistered, entry[1])
    assert_equal(/^alpha$/, entry.last[:regex])

    assert_equal(0, @engine.plist.list.size)
  end

  class MyParticipant
    attr_reader :down
    def initialize (opts)
      @down = false
    end
    def shutdown
      @down = true
    end
  end

  def test_participant_shutdown

    alpha = @engine.register_participant :alpha, MyParticipant

    @engine.plist.shutdown

    assert_equal true, alpha.down
  end

  class OptsParticipant
    attr_reader :opts
    def initialize (opts)
      @opts = opts
    end
  end

  def test_pass_block_to_participant

    alpha = @engine.register_participant :alpha, OptsParticipant

    bravo = @engine.register_participant :alpha, OptsParticipant do
      # nada
    end

    assert_nil alpha.opts[:block]
    assert_not_nil bravo.opts[:block]
    assert_equal Proc, bravo.opts[:block].class
  end
end

