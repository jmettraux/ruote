
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest39b < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestReserve39b0 < OpenWFE::ProcessDefinition
        #
        # doesn't prove it enough though...
        #
        concurrence do
            reserve :mutex => :toto do
                sequence do
                    test_alpha
                    test_bravo
                end
            end
            reserve :mutex => :toto do
                sequence do
                    test_charly
                    test_delta
                end
            end
        end
    end

    def test_0

        #log_level_to_debug

        dotest(
            TestReserve39b0, 
            [
"""
test-charly
test-delta
test-alpha
test-bravo
""".strip, 
"""
test-alpha
test-bravo
test-charly
test-delta
""".strip 
            ])
    end

    #
    # Test 1
    #

    class TestReserve39b1 < OpenWFE::ProcessDefinition
        concurrence do
            reserve :mutex => :toto do
                test_b
            end
            sequence do
                reserve :mutex => :toto do
                    test_c
                end
                reserve :mutex => :toto do
                    test_d
                end
            end
        end
    end

    def test_1
        
        dotest TestReserve39b1, "test-b\ntest-c\ntest-d"
            #
            # currently the only combination produced, could change
            # with later versions of Ruby... Hopefully :)
    end

end

