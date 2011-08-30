
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

    @engine.register_participant '.+', Ruote::NullParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    ps = @engine.ps(wfid)

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

    @engine.register_participant '.+', Ruote::NullParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)
    @engine.wait_for(1)

    fei = @engine.ps(wfid).expressions[1].fei

    @engine.cancel(fei)

    @engine.wait_for(wfid)

    assert_nil @engine.ps(wfid)
  end
end

