
#
# testing ruote
#
# Mon Apr  1 14:49:22 JST 2013
#

require File.expand_path('../base', __FILE__)


class FtReplyToParentTest < Test::Unit::TestCase
  include FunctionalBase

  def test_reply_to_parent

    @dashboard.register 'alpha', Ruote::LostReplyParticipant
    @dashboard.register 'bravo', Ruote::NullParticipant

    pdef =
      Ruote.define do
        cursor do
          alpha
        end
        bravo
      end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatched')

    ps = @dashboard.ps(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal Ruote::Exp::CursorExpression, ps.expressions.last.class
      # somehow, these are assertions for LostReplyParticipant...

    @dashboard.reply_to_parent(ps.expressions.last)

    r = @dashboard.wait_for('dispatched')
    sleep 0.100

    ps = @dashboard.ps(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal 'bravo', ps.expressions.last.applied_workitem.participant_name
  end
end

