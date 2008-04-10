
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest1 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #def xxxx_unset_0
    def test_unset_0
        dotest(
            '''
<process-definition name="n" revision="0">
    <sequence>
        <set variable="x" value="y" />
        <print>set ${x} ${v:x}</print>
        <unset variable="x" />
        <print>unset ${x} ${v:x}</print>
    </sequence>
</process-definition>
            '''.strip, 
            "set y y\nunset",
            true)
    end

    #def xxxx_unset_1
    def test_unset_2
        dotest(\
'''<process-definition name="n" revision="0">
    <sequence>
        <set field="x" value="y" />
        <print>set ${f:x}</print>
        <unset field="x" />
        <print>unset ${field:x}</print>
    </sequence>
</process-definition>''', 'set y
unset')
    end

    #def xxxx_unset_2
    def test_unset_2
        dotest(\
'''<process-definition name="n" revision="0">
    <sequence>
        <set variable="//x" value="y" />
        <print>set ${x}</print>
        <unset variable="x" />
        <print>unset ${x}</print>
    </sequence>
</process-definition>''', 'set y
unset y')
    end

    #def xxxx_unset_3
    def test_unset_3
        dotest(
            '''
<process-definition name="n" revision="0">
    <sequence>
        <set variable="//x" value="y" />
        <print>set ${x}</print>
        <unset variable="//x" />
        <print>unset ${x}</print>
    </sequence>
</process-definition>
            '''.strip, 
            "set y\nunset",
            true)
    end

    #def xxxx_unset_4
    def test_unset_4
        dotest(
            '''
<process-definition name="n" revision="0">
    <sequence>
        <set variable="/x" value="y" />
        <print>set ${x}</print>
        <unset variable="x" />
        <print>unset ${x}</print>
    </sequence>
</process-definition>
            '''.strip, 
            "set y\nunset",
            true)
    end

    #def xxxx_unset_5
    def test_unset_5
        dotest(
'''<process-definition name="n" revision="0">
    <sequence>
        <set variable="/x" value="y" />
        <print>set ${x}</print>
        <print>unset ${x}</print>
    </sequence>
    <process-definition name="sub0">
        <unset variable="x" />
    </process-definition>
</process-definition>''', 'set y
unset y')
    end

    #def xxxx_set_a0
    def test_set_a0
        dotest(\
'''<process-definition name="set_a0" revision="0">
    <sequence>
        <set variable="x">y</set>
        <print>${x}</print>
    </sequence>
</process-definition>''', 'y')
    end

    #def xxxx_set_a1
    def test_set_a1
        dotest(\
'''<process-definition name="set_a1" revision="0">
    <sequence>
        <set variable="x">
            <equals value="a" other-value="a" />
        </set>
        <print>${x}</print>
    </sequence>
</process-definition>''', 'true')
    end

    #def xxxx_set_a1f
    def test_set_a1f
        dotest(\
'''<process-definition name="set_a1f" revision="0">
    <sequence>
        <set variable="x">
            <equals value="a" other-value="${x}" />
        </set>
        <print>${x}</print>
    </sequence>
</process-definition>''', 'false')
    end

    #def xxxx_set_with_nested_string_0
    def test_set_with_nested_string_0
        dotest(\
'''<process-definition name="set_a1f" revision="0">
    <sequence>
        <set variable="x">
            ${r:"1234".reverse}
        </set>
        <print>${x}</print>
    </sequence>
</process-definition>''', '4321')
    end

    #def xxxx_set_with_nested_string_1
    def test_set_with_nested_string_1
        dotest(\
'''<process-definition name="set_a1f" revision="0">
    <sequence>
        <set field="x">
            ${r:"1234".reverse}
        </set>
        <print>${f:x}</print>
    </sequence>
</process-definition>''', '4321')
    end

end

