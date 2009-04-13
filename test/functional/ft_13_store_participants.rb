
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Apr 13 09:37:29 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/participants/store_participants'


class FtStoreParticipants < Test::Unit::TestCase
  include FunctionalBase

  PDEF = OpenWFE.process_definition :name => 'test' do
    sequence do
      participant :alpha
    end
  end

  def test_hash_participant

    alpha = @engine.register_participant :alpha, OpenWFE::HashParticipant

    fei = @engine.launch(PDEF)

    alpha.join # wake up when workitem reaches the participant

    assert_equal 1, alpha.size

    wfids = alpha.inject([]) do |a, (fei, workitem)|
      a << [ fei.wfid, workitem.fei.wfid ]; a
    end
    assert_equal [ fei.wfid ] * 2, wfids.flatten

    alpha.proceed(alpha.first_workitem)

    sleep 0.350

    assert_equal 0, alpha.size
  end

  def test_yaml_participant

    alpha = @engine.register_participant(
      :alpha,
      OpenWFE::YamlParticipant)

    fei = @engine.launch(PDEF)

    alpha.join # wake up when workitem reaches the participant

    assert_equal 1, alpha.size

    wfids = alpha.inject([]) do |a, (fei, workitem)|
      a << [ fei.wfid, workitem.fei.wfid ]; a
    end
    assert_equal [ fei.wfid ] * 2, wfids.flatten

    alpha.proceed(alpha.first_workitem)

    sleep 0.350

    assert_equal 0, alpha.size
  end

end

