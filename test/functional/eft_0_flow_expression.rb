
#
# testing ruote
#
# Mon Jun 27 11:24:21 JST 2011
#


require File.expand_path('../base', __FILE__)


class EftFlowExpressionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_root_and_root_id

    @dashboard.register :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(Ruote.define do
      sequence do
        alpha
      end
    end)

    @dashboard.wait_for(:alpha)

    fexp = @dashboard.ps(wfid).expressions.last

    assert_equal '0', fexp.root.fei.expid
    assert_equal Ruote::Exp::SequenceExpression, fexp.root.class

    assert_equal '0', fexp.root_id.expid
  end
end

