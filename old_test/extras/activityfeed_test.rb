#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 15:41:44 JST 2006
#

require 'test/unit'

require 'yaml'

require 'rubygems'

require 'openwfe/def'
require 'openwfe/workitem'
require 'openwfe/engine/engine'

require 'openwfe/extras/misc/activityfeed'


class ActivityFeedTest < Test::Unit::TestCase

  #def setup
  #end
  #def teardown
  #end

  #
  # test 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      step_one
      step_two
      step_three
    end
  end

  def test_0

    engine = OpenWFE::Engine.new({
      :definition_in_launchitem_allowed => true })

    feedservice = engine.init_service(
      'activityFeed', OpenWFE::Extras::ActivityFeedService)

    steps = []

    engine.register_participant "step_.*" do |workitem|
      steps << workitem.participant_name
    end

    li = OpenWFE::LaunchItem.new Test0
    li.message = "2 > 1 < 3"

    fei = engine.launch li
    engine.wait_for fei

    feed = feedservice.get_feed(".*")
    #puts feed.to_s

    assert_equal "step_one, step_two, step_three", steps.join(", ")
    assert_equal "OpenWFEru engine activity feed", feed.title.to_s

    assert_equal 6, feed.instance_variable_get(:@entries).size

    feed = feedservice.get_feed(".*", :upon => :reply)

    assert_equal 3, feed.instance_variable_get(:@entries).size

    entry = feed.instance_variable_get(:@entries)[0]

    assert entry

    workitem = YAML.load(entry.content.to_s)

    assert_equal OpenWFE::InFlowWorkItem, workitem.class
    assert_equal "2 > 1 < 3", workitem.message

    #puts workitem.to_s
  end

end

