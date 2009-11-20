
#
# Testing openwferu
#
# Fri Nov 20 09:27:20 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/participants/store_participants'


class FtProcessParticipants < Test::Unit::TestCase
  include FunctionalBase

  class SubDef0 < OpenWFE::ProcessDefinition
    echo 'a'
  end

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      sub0
      echo 'b'
    end
  end

  def test_process_participant

    @engine.register_participant(
      'sub0', OpenWFE::ProcessParticipant.new(SubDef0))

    assert_trace Test0, "a\nb"
  end

  class SubDef1 < OpenWFE::ProcessDefinition
    alpha
  end

  def _test_cancelling_process_participant # grrr

    alpha = @engine.register_participant(
      :alpha, OpenWFE::HashParticipant)
    @engine.register_participant(
      'sub0', OpenWFE::ProcessParticipant.new(SubDef1))

    fei = @engine.launch(Test0)

    sleep 0.500

    assert_equal 1, alpha.size

    @engine.cancel_process(fei.wfid)

    sleep 0.500

    assert_equal 0, alpha.size
  end
end

