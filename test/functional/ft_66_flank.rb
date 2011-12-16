
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

  def test_flank

    pdef = Ruote.process_definition do
      sequence do
        bravo :flank => true
        alpha
      end
    end

    @dashboard.register_participant '.+', Ruote::NullParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    ps = @dashboard.ps(wfid)

    assert_equal 4, ps.expressions.size
    assert_equal [ ps.expressions[2].fei.h ], ps.expressions[1].h.flanks
  end

  # Cancelling the sequence also cancels its "flanks".
  #
  def test_cancel

    pdef = Ruote.process_definition do
      sequence do
        bravo :flank => true
        alpha
      end
    end

    @dashboard.register_participant '.+', Ruote::NullParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(1)

    fei = @dashboard.ps(wfid).expressions[1].fei

    @dashboard.cancel(fei)

    @dashboard.wait_for(wfid)
    sleep 1.0

    assert_nil @dashboard.ps(wfid)
  end

  # Expressions replying "naturally" to their parent weren't cancelling their
  # flanks.
  #
  # https://github.com/kennethkalmer/ruote-kit/issues/13
  #
  # This test verifies the fix is in place.
  #
  def test_cancel_flank_when_done

    pdef = Ruote.process_definition do
      sequence do
        sub0 :flank => true
        echo 'over'
      end
      define 'sub0' do
        stall
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(19)

    assert_nil @dashboard.ps(wfid)
  end
end

