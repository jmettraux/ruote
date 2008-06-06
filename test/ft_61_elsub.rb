
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Jul  9 10:25:18 JST 2007
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest61 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class EngineLevelProcessDefinition < OpenWFE::ProcessDefinition
    sequence do
    end
    process_definition :name => "//elsub" do
      _print "nada"
    end
  end

  class TestDefinition0 < OpenWFE::ProcessDefinition
    elsub
    #subprocess :ref => "//elsub"
  end

  def test_0

    #log_level_to_debug

    launch EngineLevelProcessDefinition
    sleep 0.700
    dotest TestDefinition0, "nada", false, true
  end

end

