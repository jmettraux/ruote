
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Sep 11 08:48:18 JST 2007
#

require 'rubygems'
require 'openwfe/def'

require 'flowtestbase'


class FlowTest67 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    _print "hell0"
  end

  def test_0

    #log_level_to_debug

    @engine.launch Test0, :in => "2s"

    sleep 0.400

    assert_equal(
      1,
      @engine.get_scheduler.find_jobs("scheduled-launch").size)

    assert_trace ""

    sleep 2.500

    assert_trace "hell0"
  end

  #
  # TEST 1

  def test_1

    #log_level_to_debug

    t = Time.now

    @engine.launch Test0, :at => (t + 2).to_s

    sleep 0.400

    assert_equal(
      1,
      @engine.get_scheduler.find_jobs("scheduled-launch").size)

    assert_trace ""

    sleep 2.500

    assert_trace "hell0"
  end

  #
  # TEST 2

  def test_2

    #log_level_to_debug

    @engine.launch Test0, :cron => "* * * * *"

    assert_trace ""

    sleep 121

    assert_trace "hell0\nhell0"

    assert_equal(
      1,
      @engine.get_scheduler.find_jobs("scheduled-launch").size)
  end

  #
  # TEST 3

  def test_3

    #log_level_to_debug

    @engine.launch Test0, :every => "2s"

    assert_trace ""

    sleep 5

    assert_trace "hell0\nhell0"

    assert_equal(
      1,
      @engine.get_scheduler.find_jobs("scheduled-launch").size)
  end

end

