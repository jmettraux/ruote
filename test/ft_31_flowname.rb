
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'

require 'flowtestbase'


class FlowTest31 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class TestDefinition0 < ProcessDefinition
    _process_definition :name => "31 thirty one", :revision => "0 0" do
      _print "ok"
    end
  end

  #def xxxx_flowname_0
  def test_flowname_0

    dotest(TestDefinition0, "ok")
  end

end

