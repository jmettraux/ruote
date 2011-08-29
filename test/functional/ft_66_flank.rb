
#
# testing ruote
#
# Tue Aug 30 00:46:07 JST 2011
#
# Santa Barbara
#

require File.expand_path('../base', __FILE__)


class FtFlankTest < Test::Unit::TestCase
  include FunctionalBase

  def test_single_timeout

    pdef = Ruote.process_definition do
      sequence do
        bravo :flank => true
        alpha
      end
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :bravo, Ruote::StorageParticipant

    @engine.noisy = true

#    wfid = @engine.launch(pdef)
#
#    @engine.wait_for(:alpha)
#
#    assert_equal(
#      1, @engine.storage.get_many('schedules').size)
#    assert_equal(
#      'cancel', @engine.storage.get_many('schedules').first['msg']['action'])
#
#    ps = @engine.ps(wfid)
#
#    assert_not_nil ps.expressions.last.h.timers
#    assert_equal 1, ps.expressions.last.h.timers.size
#    assert_match /^at-/, ps.expressions.last.h.timers.first.first
#    assert_equal 'timeout', ps.expressions.last.h.timers.first.last
  end
end

