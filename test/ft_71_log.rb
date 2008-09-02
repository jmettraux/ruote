
#
# Testing OpenWFEru (Ruote)
#
# John Mettraux at openwfe.org
#
# Thu Sep 13 17:46:20 JST 2007
#

require 'openwfe/def'

require 'flowtestbase'


class FlowTest71 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      log 'log:0'
      log do
        'log:1'
      end
      log :message => 'log:2'
      log :message => 'log:3', :level => 'info'
    end
  end

  def test_0

    log_level_to_debug
      # required for the test ;)

    File.open 'logs/openwferu.log', 'w' do
      print ''
    end

    dotest Test0, ''

    #assert_equal 1, OpenWFE.grep("DEBUG .*log:0", "logs/openwferu.log").size
    assert_equal 1, OpenWFE.grep('log:0', 'logs/openwferu.log').size

    assert_equal 1, OpenWFE.grep('log:1', 'logs/openwferu.log').size
    assert_equal 4, OpenWFE.grep('log:.$', 'logs/openwferu.log').size

    #assert_equal 1, OpenWFE.grep("INFO .*log:3", "logs/openwferu.log").size
    assert_equal 1, OpenWFE.grep('log:3', 'logs/openwferu.log').size
  end

end

