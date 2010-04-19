
#
# testing ruote
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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant.new

    class << alpha
      def timeout
        '1s'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(13)

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size

    #logger.log.each { |l| p l }
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
    assert_equal 0, @engine.storage.get_many('schedules').size

    assert_not_nil bravo.first.fields['__timed_out__']
  end
end

