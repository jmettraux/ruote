
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'
require 'openwfe/participants/storeparticipants'


class FlowTest73 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      sub0
    end
    process_definition :name => 'sub0' do
      p0
    end
  end

  def test_0

    #log_level_to_debug

    p0 = @engine.register_participant :p0, OpenWFE::HashParticipant

    fei = launch Test0

    sleep 0.350

    assert_equal 1, p0.size
    #puts "in store : " + p0.first_workitem.fei.to_s

    wi = p0.first_workitem
    assert_equal wi.fei.wfid, fei.wfid + '.0'

    @engine.cancel_process fei

    sleep 0.350

    assert_equal 0, p0.size
  end


  #
  # Test 1
  #

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      sub1 :forget => true
      _sleep :for => '5m'
    end
    process_definition :name => 'sub1' do
      p1
    end
  end

  def test_1

    #log_level_to_debug

    p1 = @engine.register_participant :p1, OpenWFE::HashParticipant

    fei = launch Test1

    sleep 0.350

    assert_equal 1, p1.size
    #puts "in store : " + p1.first_workitem.fei.to_s

    wi = p1.first_workitem
    assert_equal wi.fei.wfid, fei.wfid + '.0'

    @engine.cancel_process(fei)

    sleep 0.350

    assert_equal 1, p1.size

    @engine.cancel_process(p1.first_workitem.fei)

    sleep 0.400

    assert_equal 0, p1.size
  end


  #
  # Test 2
  #

  class Test2 < OpenWFE::ProcessDefinition
    sequence do
      sub2 :forget => true
      p2
    end
    process_definition :name => 'sub2' do
      p20
    end
  end

  def test_2

    #log_level_to_debug

    p2 = @engine.register_participant :p2, OpenWFE::HashParticipant
    p20 = @engine.register_participant :p20, OpenWFE::HashParticipant

    fei = launch Test2

    sleep 0.400

    assert_equal 1, p2.size
    assert_equal 1, p20.size

    @engine.cancel_process p20.first_workitem.fei
    sleep 0.350
    @engine.cancel_process p2.first_workitem.fei
    sleep 0.350
  end

end

