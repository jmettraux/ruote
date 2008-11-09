
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sat Jul  7 22:44:00 JST 2007 (tanabata)
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/participants/storeparticipants'

require 'flowtestbase'


class FlowTest59 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Def59 < OpenWFE::ProcessDefinition
    concurrence do
      store_a
      store_b
    end
  end

  def test_0

    sa = @engine.register_participant("store_a", OpenWFE::HashParticipant)
    sb = @engine.register_participant("store_b", OpenWFE::HashParticipant)

    fei = launch Def59

    sleep 0.350

    ps = @engine.process_statuses
    #puts ps

    assert_equal 2, ps[fei.wfid].expressions.size
    assert_equal 2, ps[fei.wfid].applied_workitems.size
    assert_equal 0, ps[fei.wfid].errors.size

    wis = ps[fei.wfid].applied_workitems
    assert_not_equal wis[0].fei, wis[1].fei

    @engine.cancel_process fei
  end

  #
  # TEST 0b

  class Def59b < OpenWFE::ProcessDefinition
    sequence do
      alpha
      bravo
    end
  end

  def test_0b

    a = @engine.register_participant :alpha, OpenWFE::HashParticipant
    b = @engine.register_participant :bravo, OpenWFE::HashParticipant

    fei = launch Def59b

    sleep 0.350

    ps = @engine.process_statuses
    #puts ps

    assert_equal 1, ps[fei.wfid].expressions.size
    assert_equal 0, ps[fei.wfid].errors.size

    @engine.cancel_process fei
  end

  #
  # TEST 1

  class Def59_1 < OpenWFE::ProcessDefinition
    sequence do
      nada59_1
      alpha
    end
  end

  def test_1

    alpha = @engine.register_participant :alpha do
      # nothing
    end

    fei = launch Def59_1

    sleep 0.350

    ps = @engine.process_statuses
    #p ps[fei.wfid].scheduled_jobs
    #puts ps[fei.wfid].errors

    assert_equal 1, ps[fei.wfid].expressions.size
    assert_equal 1, ps[fei.wfid].branches
    assert_equal 1, ps[fei.wfid].errors.size

    #puts
    #puts ps.to_s

    @engine.cancel_process fei.wfid
  end

  #
  # TEST 2

  class Def59c < OpenWFE::ProcessDefinition
    sequence do
      bravo
      alpha
    end
  end

  def test_2

    a = @engine.register_participant :alpha, OpenWFE::HashParticipant
    b = @engine.register_participant :bravo, OpenWFE::HashParticipant

    feis = []
    feis << launch(Def59b)
    feis << launch(Def59b)
    feis << launch(Def59c)

    sleep 0.350

    assert_equal 3, @engine.list_processes(:wfname => "Def").size
    assert_equal 2, @engine.list_processes(:wfrevision => "59b").size
    assert_equal 1, @engine.list_processes(:wfrevision => "59c").size
    assert_equal 2, @engine.list_processes(:wfname => "Def", :wfrevision => "59b").size

    feis.each do |fei|
      @engine.cancel_process fei
    end

    sleep 0.350
  end

  #
  # TEST 3

  class Def59d < OpenWFE::ProcessDefinition
    _sleep "1h"
  end

  def test_3

    now = Time.now

    fei = launch Def59d

    sleep 0.350

    ps = @engine.process_status fei.wfid

    delta =  ps.scheduled_jobs.first.next_time - now
    assert(delta > 3600)
    assert(delta < 3601)

    purge_engine
  end

  #
  # TEST 4

  def test_4

    sa = @engine.register_participant('store_a', OpenWFE::HashParticipant)
    sb = @engine.register_participant('store_b', OpenWFE::HashParticipant)

    fei = launch Def59

    sleep 0.350

    ps0 = @engine.process_status fei.wfid
    pss0 = @engine.process_statuses
    sleep 0.020
    ps1 = @engine.process_status fei.wfid
    pss1 = @engine.process_statuses

    assert_not_equal ps0.timestamp, ps1.timestamp
    assert_equal pss0.object_id, pss1.object_id

    sa.forward(sa.first_workitem)

    sleep 0.350

    ps2 = @engine.process_status fei.wfid
    pss2 = @engine.process_statuses

    assert_not_equal ps0.timestamp, ps2.timestamp
    assert_not_equal pss0.object_id, pss2.object_id

    @engine.cancel_process fei

    sleep 0.350
  end

end

