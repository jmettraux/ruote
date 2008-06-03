
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'flowtestbase'


class FlowTest4 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    def test_print_0
        dotest(
'''<process-definition name="print_0" revision="0">
    <sequence>
        <print escape="true">${f:xxx}</print>
    </sequence>
</process-definition>''', "${f:xxx}")
    end

    class TestPrint1 < OpenWFE::ProcessDefinition
        sequence do
            _set :v => "toto", :value => '0'
            _print "${toto}"
            _print "${toto}", :escape => false
            _print "${toto}", :escape => true
        end
    end
    def test_print_1
        dotest TestPrint1, "0\n0\n${toto}"
    end

    def test_reval_0
        dotest(
'''<process-definition name="reval_0" revision="0">
    <sequence>
        <reval><![CDATA[
            workitem.attributes["from_ruby"] = "ok"
        ]]></reval>
        <print>${f:from_ruby}</print>
    </sequence>
</process-definition>''', "ok")
    end

    def test_reval_1
        dotest(
'''<process-definition name="reval_1" revision="0">
    <sequence>
        <set variable="field-name" value="from_ruby" />
        <reval>
            workitem.attributes["${field-name}"] = "ok"
        </reval>
        <print>${f:${field-name}}</print>
    </sequence>
</process-definition>''', "ok")
    end

    def test_reval_2
        dotest(
'''<process-definition name="reval_2" revision="0">
    <sequence>
        <set variable="field-value" value="ok" />
        <reval>
            workitem.attributes["from_ruby"] = "${field-value}"
        </reval>
        <print>${f:from_ruby}</print>
    </sequence>
</process-definition>''', "ok")
    end

    def test_reval_3
        dotest(
'''<process-definition name="reval_3" revision="0">
    <sequence>
        <set variable="v">
            <reval code="1 == 2" />
        </set>
        <print>${v}</print>
    </sequence>
</process-definition>''', "false")
    end

     class Reval4 < OpenWFE::ProcessDefinition
         _print do
             reval "sv('i', 0); 1"
         end
     end
     def test_reval_4
         dotest Reval4, '1'
     end

    #class Reval5 < OpenWFE::ProcessDefinition
    #    sequence do
    #        reval """
    #            wi.customer_name = 'dubious'
    #            'surf'
    #        """
    #        _print "${f:__result__}"
    #        _print "${f:customer_name}"
    #    end
    #end
    #def test_reval_5
    #    dotest Reval5, "surf\ndubious"
    #end

    class Reval6 < OpenWFE::ProcessDefinition
        sequence do
            set :field => "f0", :value => "3 + 2 + 2"
            set :field => "f1" do
                reval :field_code => "f0"
            end
            _print "${f:f1}"

            set :variable => "v0", :value => "5 - 5"
            set :variable => "v1" do
                reval :variable_code => "v0"
            end
            _print "${v1}"
        end
    end

    def test_reval_6
        #log_level_to_debug
        dotest Reval6, "7\n0"
    end

    #
    # DRU tests

    def test_dru_0
        dotest(
'''<process-definition name="dru_0" revision="0">
    <sequence>
        <print>${r:1+2}</print>
    </sequence>
</process-definition>''', "3")
    end

    def test_dru_1
        dotest(
'''<process-definition name="dru_1" revision="0">
    <sequence>
        <print>${r:"x"*3}</print>
    </sequence>
</process-definition>''', "xxx")
    end

    def test_dru_2
        dotest(
'''<process-definition name="dru_2" revision="0">
    <sequence>
        <set
            variable="v"
            value="${r:5*2}"
        />
        <print>${v}</print>
    </sequence>
</process-definition>''', "10")
    end

    def test_dru_3
        dotest(
'''<process-definition name="dru_3" revision="0">
    <sequence>
        <set variable="w" value="W" />
        <set variable="v">
            <!--
            <reval>self.lookup_variable("w") * 3</reval>
            <reval>lookup_variable("w") * 3</reval>
            -->
            <reval>"W" * 3</reval>
        </set>
        <print>${v}</print>
    </sequence>
</process-definition>''', "WWW")
    end

    def test_dru_4
        dotest(
'''<process-definition name="dru_4" revision="0">
    <sequence>
        <set variable="v">
            <reval>fei.workflow_definition_name</reval>
        </set>
        <print>${v}</print>

        <print>${r:fei.workflow_definition_name}</print>
    </sequence>
</process-definition>''', """dru_4
dru_4""")
    end

    class TestSetEscape0 < OpenWFE::ProcessDefinition
        sequence do
            _set :v => "t0" do
                "This is ${my template}"
            end
            _set :v => "t1", :escape => true do
                "This is ${my template}"
            end
            _set :v => "t2", :val => "This is ${my template}", :escape => "true"
            peek
            #_print { v "t0" }
            #_print { v "t1" }
        end
    end
    def test_set_escape_0
        @engine.register_participant :peek do |fexp, wi|
            @tracer << fexp.get_environment.variables['t0']
            @tracer << "\n"
            @tracer << fexp.get_environment.variables['t1']
            @tracer << "\n"
            @tracer << fexp.get_environment.variables['t2']
            @tracer << "\n"
        end
        dotest(
            TestSetEscape0,
            "This is \nThis is ${my template}\nThis is ${my template}")
    end

end

