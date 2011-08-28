
#
# testing ruote
#
# Mon Aug 15 20:43:11 JST 2011
#
# Right before the international date change line
#

require File.expand_path('../base', __FILE__)


class FtTimersTest < Test::Unit::TestCase
  include FunctionalBase

  def test_single_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha :timers => '1d: timeout'
        bravo
      end
    end

    @engine.register_participant /alpha|bravo/, Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    assert_equal(
      1, @engine.storage.get_many('schedules').size)
    assert_equal(
      'cancel', @engine.storage.get_many('schedules').first['msg']['action'])

    ps = @engine.ps(wfid)

    assert_not_nil ps.expressions.last.h.timers
    assert_equal 1, ps.expressions.last.h.timers.size
    assert_match /^at-/, ps.expressions.last.h.timers.first.first
    assert_equal 'timeout', ps.expressions.last.h.timers.first.last
  end
end

