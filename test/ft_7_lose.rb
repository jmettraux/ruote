
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


class FlowTest7 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    def test_lose_0
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>

        <concurrence count="1">
            <lose>
                <sequence>
                    <sleep for="2s" />
                    <print>I should not be printed</print>
                </sequence>
            </lose>
            <sequence>
                <print>ok 0</print>
            </sequence>
        </concurrence>

        <print>- - -</print>

        <concurrence count="1">
            <lose>
                <sequence>
                    <print>ok 1</print>
                    <set variable="v0" value="true" />
                </sequence>
            </lose>
            <sequence>
                <sleep for="400" />
                <print>ok 2</print>
            </sequence>
        </concurrence>

        <print>v0 : ${v0}</print>
        <if>
            <equals variable-value="v0" other-value="true" />
            <print>ok 3</print>
        </if>

        <print>- - -</print>

        <concurrence count="1">
            <lose>
                <sequence>
                    <sleep for="400" />
                        <!-- more than the 250 ms precision -->
                    <print>ok 4</print>
                    <set variable="v1" value="true" />
                </sequence>
            </lose>
            <sequence>
                <print>ok 5</print>
            </sequence>
        </concurrence>

        <print>v1 : ${v1}</print>
        <if>
            <equals field-value="v1" other-value="true" />
            <print>ok 6</print>
        </if>

        <print>done.</print>

    </sequence>
</process-definition>''', 
            """ok 0
- - -
ok 1
ok 2
v0 : true
ok 3
- - -
ok 5
v1 : 
done.""", 
            3.000,
            true)
    end

end

