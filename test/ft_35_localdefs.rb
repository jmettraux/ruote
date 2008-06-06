
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'
require 'openwfe/workitem'
require 'openwfe/participants/storeparticipants'

require 'flowtestbase'


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

  def test_local_0

    #log_level_to_debug

    li = OpenWFE::LaunchItem.new
    li.wfdurl = "file:doc/res/defs/testdef.rb"

    dotest(
      li,
      """a
b
c""")
  end


  #
  # TEST 1

  #def xxxx_local_1
  def test_local_1

    li = OpenWFE::LaunchItem.new
    li.wfdurl = "doc/res/defs/testdef.rb"

    dotest(
      li,
      """a
b
c""")
  end


  #
  # TEST 2

  def test_local_2

    launch "file:doc/res/defs/testdef.rb"
    sleep 0.300
    assert_equal @tracer.to_s, "a\nb\nc"
  end

end

