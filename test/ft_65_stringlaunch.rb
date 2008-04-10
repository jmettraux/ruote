
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest65 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end


    #
    # Test 0
    #

    TEST0 = """
    class Test0 < OpenWFE::ProcessDefinition
        _print 'ok.'
    end
    """.strip

    def test_0

        @engine.launch TEST0
        sleep 0.350
        assert_equal "ok.", @tracer.to_s
    end


    #
    # Test 1
    #

    TEST1 = """
<process-definition name='65_1' revision='0.1'>
    <print>ok.</print>
</process-definition>
    """.strip

    def test_1

        @engine.launch TEST1

        sleep 0.350
        assert_equal "ok.", @tracer.to_s
    end

end

