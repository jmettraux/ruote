
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Dec 11 09:49:18 JST 2006
# Narita terminal 1
#

require 'flowtestbase'


class FlowTest6 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    def test_lambda_0

        dotest(
'''<process-definition name="lambda_0" revision="0">
    <sequence>
        <set variable="inside1x">
            <process-definition>
                <print>bonjour ${name}</print>
            </process-definition>
        </set>

        <inside1x name="world" />
        <print>over</print>
    </sequence>
</process-definition>''', 
            "bonjour world\nover")
    end

    #
    # TEST 1

    class Test1 < OpenWFE::ProcessDefinition
        sequence do
            _set :v => "inside1r" do
                process_definition do
                    _print "hello ${name}"
                end
            end
            inside1r :name => "mundo"
            _print "done."
        end
    end

    def test_1

        #log_level_to_debug

        dotest(Test1, "hello mundo\ndone.")
    end

end

