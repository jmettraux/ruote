
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest0 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    def test_print
        dotest(
'''<process-definition name="n" revision="0">
    <print>ok</print>
</process-definition>''', "ok")
    end

    def test_empty
        dotest(
'''<process-definition name="n" revision="0">
</process-definition>''', '')
    end

    def test_2
        #log_level_to_debug
        dotest(
'''<process-definition name="n" revision="0">
    <sequence>
        <set variable="x" value="y" />
        <print>${x} ${v:x}</print>
    </sequence>
</process-definition>''', 'y y')
    end

    def test_3
        #log_level_to_debug
        dotest(
'''<process-definition name="n" revision="0">
    <sequence>
        <set field="x" value="y" />
        <print>${f:x} ${field:x}</print>
    </sequence>
</process-definition>''', 'y y')
    end

    def test_dollar_notation_2
        dotest(
'''<process-definition name="n" revision="0">
    <sequence>
        <print>${f:x}X${field:x}</print>
    </sequence>
</process-definition>''', 'X')
    end

end

