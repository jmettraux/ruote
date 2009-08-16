
#
# Testing Ruote (OpenWFEru)
#
# Sun Aug 16 14:25:35 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtParticipantTimeoutTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant_defined_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    class << alpha
      def timeout
        '1s'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)
    sleep 1.5

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size
    assert_equal 1, logger.log.select { |e| e[2][:scheduler] == true }.size
    assert_equal 0, @engine.scheduler.jobs.size

    assert_not_nil bravo.first.fields['__timed_out__']
  end
end

