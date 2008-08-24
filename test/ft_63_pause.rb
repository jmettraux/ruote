
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'
require 'openwfe/participants/storeparticipants'


class FlowTest63 < Test::Unit::TestCase
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
      participant :alpha
      _print "done."
    end
  end

  def test_0

    #log_level_to_debug

    sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

    pause_events = []
    @engine.get_expression_pool.add_observer :all do |channel, args|
      pause_events << [ channel, args ] if [ :pause, :resume ].include?(channel)
    end

    fei = @engine.launch Test0

    sleep 0.350

    assert_equal(
      @engine.process_status(fei.wfid).expressions[0].fei.wfid,
      fei.wfid)
    #puts @engine.process_status(fei.wfid)
    #puts @engine.list_process_status

    assert ! @engine.process_status(fei.wfid).paused?
    assert ! @engine.is_paused?(fei.wfid)

    @engine.pause_process fei.workflow_instance_id

    assert @engine.process_status(fei.wfid).paused?
    assert @engine.is_paused?(fei.wfid)
    assert_equal [ [ :pause, fei.wfid ] ], pause_events

    hp = @engine.get_participant :alpha
    wi = hp.first_workitem
    hp.forward wi

    sleep 0.350

    assert_equal @engine.process_status(fei.wfid).errors.size, 1
    assert_equal @tracer.to_s, ''

    @engine.resume_process fei.workflow_instance_id

    #assert ! @engine.process_status(fei.wfid).paused?

    #unless @engine.get_expression_storage.is_a?(
    #  OpenWFE::InMemoryExpressionStorage)
    #
    #  ps = @engine.process_status fei.wfid
    #  #puts ps
    #  assert_equal ps.errors.size, 0
    #  assert ! ps.paused?
    #end

    sleep 0.350

    assert_equal(
      [ [ :pause, fei.wfid ], [ :resume, fei.wfid ] ],
      pause_events)

    assert_nil @engine.process_status(fei.wfid)
    assert_equal @tracer.to_s, 'done.'
  end


  #
  # Test 1
  #

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      participant :alpha
      _print "done."
    end
  end

  def test_1

    #log_level_to_debug

    sa = @engine.register_participant :alpha, OpenWFE::NullParticipant

    fei = @engine.launch Test1

    sleep 0.350

    assert ! @engine.process_status(fei.wfid).paused?

    @engine.pause_process fei.wfid

    sleep 0.350

    assert @engine.process_status(fei.wfid).paused?

    @engine.resume_process fei.wfid

    assert ! @engine.process_status(fei.wfid).paused?

    @engine.cancel_process fei.wfid

    sleep 0.350
  end

end

