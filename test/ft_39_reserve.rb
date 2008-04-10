
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest39 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end


    #
    # Test 0
    #

    class TestReserve39a0 < OpenWFE::ProcessDefinition
        reserve :mutex => :toto do
            _print "ok"
        end
    end

    def test_0

        dotest TestReserve39a0, "ok", true
    end

    #
    # Test 1
    #
    
    # became obsolete

    #
    # Test 2
    #

    # moved to ft_39b_reserve.rb

    #
    # Test 3
    #

    class TestReserve39a3 < OpenWFE::ProcessDefinition
        reserve :mutex => :toto do
        end
    end

    def test_3
        dotest TestReserve39a3, "", true
    end

end

