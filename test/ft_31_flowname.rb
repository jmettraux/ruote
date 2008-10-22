
#
# Testing OpenWFEru (Ruote)
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'

require 'flowtestbase'


class FlowTest31 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
    _process_definition :name => "31 thirty one", :revision => "0 0" do
      _print "ok"
    end
  end

  def test_flowname_0

    dotest(TestDefinition0, "ok")
  end

end

