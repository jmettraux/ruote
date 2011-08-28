
#
# testing ruote
#
# Mon Aug 15 20:43:11 JST 2011
#
# Right before the international date change line
#

require File.expand_path('../base', __FILE__)


class FtTimersTest < Test::Unit::TestCase
  include FunctionalBase

  def test_single_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha :timers => '1d: timeout'
        bravo
      end
    end

    @engine.register_participant /alpha|bravo/, Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    assert_equal(
      1, @engine.storage.get_many('schedules').size)
    assert_equal(
      'cancel', @engine.storage.get_many('schedules').first['msg']['action'])
  end

#  def test_timeout
#
#    pdef = Ruote.process_definition do
#      sequence do
#        alpha :timeout => '1.1'
#        bravo
#      end
#    end
#
#    @engine.register_participant :alpha, Ruote::StorageParticipant
#    sto = @engine.register_participant :bravo, Ruote::StorageParticipant
#
#    #noisy
#
#    wfid = @engine.launch(pdef)
#    wait_for(:bravo)
#
#    assert_equal 1, sto.size
#    assert_equal 'bravo', sto.first.participant_name
#
#    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
#    assert_equal 0, @engine.storage.get_many('schedules').size
#
#    assert_equal wfid, sto.first.fields['__timed_out__'][0]['wfid']
#    assert_equal '0_0_0', sto.first.fields['__timed_out__'][0]['expid']
#    assert_equal 'participant', sto.first.fields['__timed_out__'][2]
#
#    assert_equal(
#      { 'timeout' => '1.1', 'ref' => 'alpha' },
#      sto.first.fields['__timed_out__'][3])
#  end
end

