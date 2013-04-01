
#
# testing ruote
#
# Thu Jul 26 15:17:44 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtResparkTest < Test::Unit::TestCase
  include FunctionalBase

  def test_respark

    @dashboard.register do
      alpha Ruote::NullParticipant
    end

    pdef = Ruote.define do
      concurrence do
        alpha; alpha
      end
    end

    wfid = @dashboard.launch(pdef)
    2.times { @dashboard.wait_for('dispatched') }

    # flow stalled...

    @dashboard.register do
      alpha Ruote::StorageParticipant
    end

    @dashboard.respark(wfid)

    2.times { @dashboard.wait_for('dispatched') }

    assert_equal 2, @dashboard.storage_participant.size
  end

  # Errors are not re-applied
  #
  def test_respark_when_errors

    @dashboard.register 'alpha', Ruote::NullParticipant
    @dashboard.register 'bravo' do |workitem|
      raise "nada"
    end

    pdef = Ruote.define do
      concurrence do
        alpha; bravo
      end
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for('error_intercepted')

    error_at = @dashboard.process(wfid).errors.first.at

    # flow stalled...

    @dashboard.register 'alpha', Ruote::StorageParticipant

    @dashboard.respark(wfid)

    @dashboard.wait_for('dispatched')
    sleep 0.100

    assert_equal 1, @dashboard.storage_participant.size
    assert_equal error_at, @dashboard.process(wfid).errors.first.at
  end

  def test_respark_errors_too

    @dashboard.register 'alpha', Ruote::NullParticipant
    @dashboard.register 'bravo' do |workitem|
      raise "nada"
    end

    pdef = Ruote.define do
      concurrence do
        alpha; bravo
      end
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for('error_intercepted')

    error_at = @dashboard.process(wfid).errors.first.at

    # flow stalled...

    @dashboard.register 'alpha', Ruote::StorageParticipant

    @dashboard.respark(wfid, 'errors_too' => true)

    @dashboard.wait_for('error_intercepted')
    sleep 0.100

    assert_equal 1, @dashboard.storage_participant.size
    assert_not_equal error_at, @dashboard.process(wfid).errors.first.at
  end

#  def test_respark_cursor
#
#    @dashboard.register 'alpha', Ruote::LostReplyParticipant
#
#    pdef =
#      Ruote.define do
#        cursor do
#          alpha
#        end
#      end
#
#    wfid = @dashboard.launch(pdef)
#
#    @dashboard.wait_for('dispatched')
#
#    ps = @dashboard.ps(wfid)
#
#    assert_equal 0, ps.errors.size
#    assert_equal 2, ps.expressions.size
#      # somehow, these are assertions for LostReplyParticipant...
#
#    ps.leaves.each do |l|
#      p l.class
#      p l.applied_workitem
#    end
#
#    @dashboard.respark(wfid)
#    @dashboard.wait_for('dispatched')
#  end
  #
  # not good: the respark fails since the child is gone...
  # for now, work on Dashboard#reply(fei, workitem=nil)...
end

