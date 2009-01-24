
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Sun Nov  2 16:40:54 JST 2008
#

require File.dirname(__FILE__) + '/flowtestbase'

require 'openwfe/def'
require 'openwfe/participants/participants'


class FlowTest54d < Test::Unit::TestCase
  include FlowTestBase


  #
  # Test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    concurrence do

      listen :to => 'channel_z', :wfid => :current do
        _print 'l ${r:fei.wfid}'
      end

      sequence do
        _sleep '300'
        channel_z
      end
    end
  end

  class Test0b < OpenWFE::ProcessDefinition
    channel_z
  end

  def test_0

    @engine.register_participant :channel_z do |workitem|
      @tracer << "z #{workitem.fei.wfid}\n"
    end

    #log_level_to_debug

    fei0 = @engine.launch(Test0)
    fei0b = @engine.launch(Test0b)

    sleep 0.7

    #puts @tracer.to_s

    assert_equal(
      %{
z #{fei0b.wfid}
z #{fei0.wfid}
l #{fei0.wfid}
      }.strip,
      @tracer.to_s)

    #@engine.cancel_process(fei0b)
    #@engine.cancel_process(fei0)
    #sleep 0.4
  end

end

