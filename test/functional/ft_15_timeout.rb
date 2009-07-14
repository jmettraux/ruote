
#
# Testing Ruote (OpenWFEru)
#
# Sun Jun 28 16:45:57 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtTimeoutTest < Test::Unit::TestCase
  include FunctionalBase

  def test_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha :timeout => '1s'
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    sleep 1.5

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size
    assert_equal 1, logger.log.select { |e| e[2][:scheduler] == true }.size
    assert_equal 0, @engine.scheduler.jobs.size

    assert_not_nil bravo.first.fields['__timed_out__']
  end

  def test_cancel_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha :timeout => '2s'
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    sleep 1

    assert_equal 1, alpha.size

    @engine.cancel_expression(alpha.first.fei)

    sleep 0.5

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size
    assert_equal 0, @engine.scheduler.jobs.size
  end
end

