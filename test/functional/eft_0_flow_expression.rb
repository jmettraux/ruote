
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

  class MyParticipant < Ruote::Participant
    def on_workitem
      workitem.fields['roots'] = [
        fexp.root.class.to_s, fexp.root(true).class.to_s
      ]
      reply
    end
  end

  def test_root_stubborn

    @dashboard.register :toto, MyParticipant

    pdef = Ruote.define do
      concurrence :remaining => 'forget', :wait_for => 1 do
        sequence do
          # exit immediately
        end
        sequence do
          wait '1s'
          toto
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('terminated')
    r = @dashboard.wait_for('ceased')

    assert_equal(
      %w[ Ruote::Exp::ConcurrenceExpression NilClass ],
      r['workitem']['fields']['roots'])
  end
end

