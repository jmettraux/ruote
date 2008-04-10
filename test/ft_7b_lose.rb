
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Dec 25 14:27:48 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest7b < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end


    def test_1

        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <concurrence
            count="1"
        >
            <lose>
                <sequence>
                    <sleep for="500" />
                    <print>a</print>
                </sequence>
            </lose>
            <print>b</print>
        </concurrence>
        <print>c</print>
    </sequence>
</process-definition>''', 
            """b
c""")
            #true,
            #true)
    end


    #
    # TEST 2

    class TestDefinition2 < OpenWFE::ProcessDefinition
        def make
            process_definition :name => "7_lose", :revision => "2" do
                sequence do
                    _print "before"
                    concurrence :count => 1 do
                        lose do
                            sequence do
                                _sleep :for => 350
                                _print "ok 4"
                            end
                        end
                        sequence do 
                            _print "ok 5"
                        end
                    end
                    _print "after"
                end
            end
        end
    end

    def test_2

        dotest(
            TestDefinition2, 
            [ 'before', 'ok 5', 'after' ].join("\n"))
    end

end

