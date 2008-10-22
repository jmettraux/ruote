
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/participants/storeparticipants'

require 'flowtestbase'


class FlowTest27 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
    sequence do
      store_p
    end
  end

  def test_gfp_0

    #sp = @engine.register_participant("store_p", OpenWFE::YamlParticipant)
    sp = @engine.register_participant "store_p", OpenWFE::HashParticipant

    fei = launch TestDefinition0

    sleep 0.350

    l = @engine.process_stack fei.wfid

    #print_exp_list l

    assert_equal 3, l.size

    ps = @engine.list_process_status
    #puts
    #puts ps[fei.parent_wfid].to_s
    #puts

    assert_equal 0, ps[fei.parent_wfid].errors.size
    assert_equal 1, ps[fei.parent_wfid].expressions.size
    assert_kind_of OpenWFE::ParticipantExpression, ps[fei.parent_wfid].expressions[0]

    assert_not_nil ps[fei.parent_wfid].launch_time

    ps = @engine.list_process_status fei.wfid[0, 4]

    assert_equal 0, ps[fei.parent_wfid].errors.size
    assert_equal 1, ps[fei.parent_wfid].expressions.size
    assert_kind_of OpenWFE::ParticipantExpression, ps[fei.parent_wfid].expressions[0]

    #
    # resume process

    wi = sp.first_workitem

    sp.forward(wi)

    #@engine.wait_for fei
    wait_for fei

    assert_equal 0, sp.size
  end


  #
  # TEST 0b

  class Gfp27b < OpenWFE::ProcessDefinition
    sequence do
      store_p
      _print "pass"
    end
  end

  def test_gfp_0b

    log_level_to_debug

    sp = @engine.register_participant "store_p", OpenWFE::YamlParticipant

    #fei = @engine.launch TestDefinition0
    fei = launch Gfp27b

    sleep 0.350

    #l = @engine.get_process_stack(fei.wfid)
    l = @engine.process_stack fei
      #
      # shortcut version

    #print_exp_list l

    assert_equal 3, l.size

    l = @engine.list_processes
    assert_equal 1, l.size

    l = @engine.list_processes(
      :consider_subprocesses => false, :wfid_prefix => "nada")
    assert_equal 0, l.size

    l = @engine.list_workflows(
      :consider_subprocesses => false, :wfid_prefix => fei.wfid[0, 3])
    assert_equal 1, l.size

    l = @engine.process_stack(fei, true) # unapplied exps as well
    #print_exp_list l
    assert_equal 4, l.size

    #
    # resume flow and terminate it

    wi = sp.first_workitem

    assert_not_nil wi

    sp.forward(wi)

    #@engine.wait_for fei
    wait_for(fei)

    #p sp.list_workitems.collect { |wi| wi.fei.to_s }
    assert_equal 0, sp.size
  end

end

