
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Apr  8 12:24:27 JST 2008
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest14c < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      sub0 :forget => true
      sub0 :forget => true
    end
    process_definition :name => "sub0" do
      _print "${r:fei.wfid[-2..-1]}"
    end
  end

  def test_0

    #log_level_to_debug

    dotest Test0, ".0\n.1", 0.750
  end


  #
  # TEST 1

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      sub0 :forget => true
      sub0
    end
    process_definition :name => "sub0" do
      _print "${r:fei.wfid[-2..-1]}"
    end
  end

  def test_1

    #log_level_to_debug

    dotest Test1, ".0\n.1", 0.750
  end

end

