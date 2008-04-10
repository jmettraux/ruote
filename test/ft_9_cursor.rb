
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'openwfe/def'
require 'flowtestbase'


class FlowTest9 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    def test_cursor_0
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <cursor>
        <print>a</print>
        <print>b</print>
    </cursor>
</process-definition>''', 
"""a
b""")
    end

    def test_cursor_1
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <cursor>
        <print>a</print>
        <print>b</print>
        <cancel />
        <print>c</print>
    </cursor>
</process-definition>''', 
"""a
b""")
    end

    def test_cursor_2
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <cursor>
        <print>a</print>
        <print>b</print>
        <skip step="2" />
        <print>c</print>
    </cursor>
</process-definition>''', 
"""a
b""")
    end

    def test_cursor_2b
        #
        # ZigZag test
        #
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <cursor>
        <print>a</print>
        <skip step="3" />
        <print>b</print>
        <skip step="2" />
        <back step="2"/>
        <print>c</print>
    </cursor>
</process-definition>''', 
"""a
b
c""")
    end

    def test_cursor_3
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <cursor>
        <print>a</print>
        <skip step="2" />
        <print>b</print>
        <print>c</print>
    </cursor>
</process-definition>''', 
"""a
c""")
    end

    def test_cursor_4
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <cursor>
            <print>a</print>
            <set field="__cursor_command__" value="skip 2" />
            <print>b</print>
            <print>c</print>
        </cursor>
        <print>d</print>
    </sequence>
</process-definition>''', 
"""a
c
d""")
    end

    def test_cursor_5
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <cursor>
        <print>a</print>
        <skip>2</skip>
        <print>b</print>
        <print>c</print>
    </cursor>
</process-definition>''', 
"""a
c""")
    end

    class TestCursor6 < OpenWFE::ProcessDefinition
        cursor do
            _print "a"
            skip "2"
            _print "b"
            _print "c"
            skip 2
            _print "d"
        end
    end

    def test_cursor_6
        dotest(TestCursor6, "a\nc")
    end

end

