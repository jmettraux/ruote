
#
# testing ruote
#
# Sat Oct 13 06:09:12 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtPauseOnApplyTest < Test::Unit::TestCase
  include FunctionalBase

  def test_pause_apply_then_resume

    @dashboard.register do
      alpha Ruote::StorageParticipant
      bravo Ruote::NoOpParticipant
    end

    pdef = Ruote.define do
      echo 'a'
      alpha
      echo 'b'
      bravo :pos => [ 1, 1 ]
      bravo :pos => [ 2, 1 ]
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(:alpha)

    tid = @dashboard.add_tracker(
      wfid,
      'pre_apply',
      nil,
      { 'tree.1.pos' => [ [ 1, 1 ] ] },
      { '_auto_remove' => true, '_alter' => 'merge', 'state' => 'paused' })

    assert_equal String, tid.class

    wi = @dashboard.storage_participant.first
    @dashboard.storage_participant.proceed(wi)

    @dashboard.wait_for('apply')      # echo 'b'
    r = @dashboard.wait_for('apply')  # bravo :pos => [ 1, 1 ]

    assert_equal nil, r['state']

    ps = @dashboard.ps(wfid)
    bravo = ps.expressions.last

    assert_equal 'paused', bravo.state
    assert_not_nil bravo.h.paused_apply

    @dashboard.resume(bravo)

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    assert_equal 0, @dashboard.storage.get_trackers['trackers'].size
  end
end

