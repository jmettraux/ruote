
#
# Testing Ruote (OpenWFEru)
#
# Wed Jun  3 08:42:07 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cancel_process

    pdef = Ruote.process_definition do
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait
    ps = @engine.process_status(wfid)
    assert_equal 1, alpha.size

    assert_not_nil ps

    @engine.cancel_process(wfid)

    wait
    ps = @engine.process_status(wfid)

    assert_nil ps
    assert_equal 0, alpha.size

    assert_equal 2, logger.log.select { |e| e[0] == :processes }.size
    assert_equal 3, logger.log.select { |e| e[1] == :cancel }.size
  end

  def _test_cancel_expression

    pdef = Ruote.process_definition do
      sequence do
        alpha
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    wi = alpha.first

    @engine.cancel_expression(wi.fei)
    wait_for(wfid)

    assert_not_nil bravo.first
  end
end

