
#
# Testing Ruote (OpenWFEru)
#
# Mon May 18 22:25:57 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtParticipantRegistrationTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_register

    #noisy

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    wait

    entry = logger.log.last
    assert_equal :registered, entry[1]
    assert_equal :alpha, entry.last[:regex]
    assert_equal Ruote::BlockParticipant, entry.last[:participant]

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

    wait

    entry = logger.log.last
    assert_equal(:unregistered, entry[1])
    assert_equal(/^alpha$/, entry.last[:regex])

    assert_equal 0, @engine.plist.list.size
  end

  def test_participant_unregister

    pa = @engine.register_participant :alpha do |workitem|
    end

    @engine.unregister_participant pa

    wait

    entry = logger.log.last
    assert_equal(:unregistered, entry[1])
    assert_equal(/^alpha$/, entry.last[:regex])

    assert_equal(0, @engine.plist.list.size)
  end
end

