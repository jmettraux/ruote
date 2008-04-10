
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'flowtestbase'


$s = (0..9).to_a.join("\n").strip


class FlowTest10 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    def test_loop_0

        #log_level_to_debug

        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <reval>$i = 0</reval>
        <loop>
            <print>${r:$i}</print>
            <reval>$i = $i + 1</reval>
            <if>
                <equals value="${r:$i}" other-value="10" />
                <break/>
            </if>
        </loop>
    </sequence>
</process-definition>''', 
        $s)
    end

    def test_loop_1
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <reval>$i = 0</reval>
        <loop>
            <print>${r:$i}</print>
            <reval>$i = $i + 1</reval>
            <if rtest="$i == 10">
                <break/>
            </if>
        </loop>
    </sequence>
</process-definition>''', 
        $s)
    end

    def test_loop_2
        #log_level_to_debug
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <reval>$i = 0</reval>
        <loop>
            <print>${r:$i}</print>
            <reval>$i = $i + 1</reval>
            <break if="${r:$i} == 10" />
        </loop>
    </sequence>
</process-definition>''', 
        $s)
    end

    def test_loop_3
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <reval>$i = 0</reval>
        <loop>
            <print>${r:$i}</print>
            <reval>$i = $i + 1</reval>
            <break if="${r:$i == 10}" />
        </loop>
    </sequence>
</process-definition>''', 
        $s)
    end

    def test_loop_4
        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <reval>$i = 0</reval>
        <loop>
            <print>${r:$i}</print>
            <reval>$i = $i + 1</reval>
            <break rif="$i == 10" />
        </loop>
    </sequence>
</process-definition>''', 
        $s)
    end

    def test_loop_5

        #log_level_to_debug

        dotest(
'<process-definition name="'+name_of_test+'''" revision="0">
    <sequence>
        <reval>$i = 0</reval>
        <loop>
            <!--
            <reval>$i = $i + 1</reval>
            <set field="f" value="${r:$i}" />
            -->
            <set field="f">
                <reval>$i = $i + 1</reval>
            </set>
            <print>${r:$i}</print>
            <break if="${f:f}" />
        </loop>
    </sequence>
</process-definition>''', 
        '1')
    end

end

