
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'
require 'flowtestbase'


class FlowTest2c < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #def xxxx_con_0
    def test_con_0
        dotest(
            '''<process-definition name="con" revision="0">
    <concurrence>
        <print>a</print>
        <print>b</print>
    </concurrence>
</process-definition>''', 
            [ '''a
b''', 
              '''b
a''' 
            ])
    end


    #
    # TEST 1

    class TestCon2c1 < OpenWFE::ProcessDefinition
        sequence do
            concurrence :count => "1", :remaining => "forget" do
                _print "a"
                sequence do
                    _sleep "500"
                    _print "b"
                end
            end
            _print "c"
        end
    end

    def test_con_1
        dotest(
            TestCon2c1, 
            "a\nc\nb",
            2)
    end

end

