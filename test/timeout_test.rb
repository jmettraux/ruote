#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 15:41:44 JST 2006
#

require 'rubygems'

require 'test/unit'

require 'openwfe/engine/engine'
require 'openwfe/def'
require 'openwfe/participants/storeparticipants'

require 'rutest_utils'


class TimeoutTest < Test::Unit::TestCase

  #def setup
  #  @engine = $WORKFLOW_ENGINE_CLASS.new()
  #end

  #def teardown
  #end

  class TimeoutDefinition0 < OpenWFE::ProcessDefinition
    sequence do
      participant :ref => "albert", :timeout => "500"
      _print "timedout? ${f:__timed_out__}"
      _print "over ${f:done}"
    end
  end

  def test_0

    albert = OpenWFE::HashParticipant.new

    engine = OpenWFE::Engine.new :definition_in_launchitem_allowed => true

    engine.application_context["__tracer"] = Tracer.new

    engine.register_participant :albert, albert

    li = OpenWFE::LaunchItem.new TimeoutDefinition0

    engine.launch li

    sleep 2

    s = engine.application_context["__tracer"].to_s

    engine.stop

    #puts "trace is >#{s}<"
    #puts "albert.size is #{albert.size}"

    assert_equal 0, albert.size, "wi was not removed from workitem store"
    assert_equal "timedout? true\nover", s, "flow did not reach 'over'"
  end

  def test_1

    albert = OpenWFE::HashParticipant.new

    engine = OpenWFE::Engine.new :definition_in_launchitem_allowed => true

    engine.application_context["__tracer"] = Tracer.new

    engine.register_participant(:albert, albert)

    pjc = engine.get_scheduler.pending_job_count
    assert_equal 0, pjc

    li = OpenWFE::LaunchItem.new TimeoutDefinition0

    engine.launch li

    sleep 0.300

    wi = albert.list_workitems(nil)[0]
    wi.done = "ok"
    albert.proceed(wi)

    sleep 0.300

    s = engine.application_context["__tracer"].to_s

    #puts "trace is >#{s}<"
    #puts "albert.size is #{albert.size}"

    # in this test, the participant doesn't time out

    assert_equal 0, albert.size, "wi was not removed from workitem store"
    assert_equal "timedout? \nover ok", s, "flow did not reach 'over ok'"

    pjc = engine.get_scheduler.pending_job_count

    assert_equal 0, pjc, "pending_jobs_count is at #{pjc}, should be at 0"
  end

  class Test2 < OpenWFE::ProcessDefinition
    albert :timeout => '10s'
  end

  def test_2

    engine = OpenWFE::Engine.new :definition_in_launchitem_allowed => true

    workitem = nil

    engine.register_participant 'albert' do |wi|
      workitem = wi.dup
    end

    fei = engine.launch(Test2)

    sleep 0.350

    assert_equal(
      1, workitem.attributes['__timeouts__'].size)
    assert_equal(
      5, workitem.attributes['__timeouts__']["#{fei.wfid}__0.0"].size)

    assert_equal(
      5, workitem.current_timeout.size)

    #puts workitem
  end

end

