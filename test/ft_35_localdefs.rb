
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/workitem'
require 'openwfe/participants/storeparticipants'

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest35 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #  super
  #  @engine.ac[:remote_definitions_allowed] = true
  #end


  #
  # TEST 0

  def test_0

    #log_level_to_debug

    li = OpenWFE::LaunchItem.new
    li.wfdurl = 'file:test/_testdef.rb'

    dotest(li, %w(a b c).join("\n"))
  end


  #
  # TEST 1

  def test_1

    li = OpenWFE::LaunchItem.new
    li.wfdurl = "test/_testdef.rb"

    dotest(li, %w(a b c).join("\n"))
  end


  #
  # TEST 2

  def test_2

    launch 'file:test/_testdef.rb'
    sleep 0.300
    assert_equal @tracer.to_s, "a\nb\nc"
  end

end

