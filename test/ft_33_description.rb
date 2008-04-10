
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'
require 'flowtestbase'


class FlowTest33 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # TEST 0

    class TestDefinition0 < ProcessDefinition
        description "nada"
        _print "${description}"
    end

    #def xxxx_0
    def test_0
        dotest(TestDefinition0, "nada")
    end

    #
    # TEST 1

    def test_1
        dotest("""<process-definition name='test_1' revision='x'>
    <description>nada</description>
    <print>${description}</print>
</process-definition>
""", "nada")
    end

    #
    # TEST 2

    class TestDefinition2 < ProcessDefinition
        description :lang => "fr" do "nada" end
        sequence do
            _print "${description}"
            _print "${description__fr}"
        end
    end

    #def xxxx_2
    def test_2
        dotest(TestDefinition2, "nada\nnada")
    end

    #
    # TEST 3

    class TestDefinition3 < ProcessDefinition
        description "nothing"
        description :lang => "es" do "nada" end
        sequence do
            _print "${description}"
            _print "${description__es}"
        end
    end

    #def xxxx_3
    def test_3
        dotest(TestDefinition3, "nothing\nnada")
    end

    #
    # TEST 4

    def test_4

        @engine.register_participant :check do |fexp, wi|
            @tracer << fexp.lookup_variable('description').class.name
            @tracer << "\n"
        end

        dotest(
"""<process-definition name='test_1' revision='x'>
    <description language='en'>nothing</description>
    <description language='es'>nada</description>
    <sequence>
        <participant ref='check' />
        <print>${description}</print>
        <print>${description__en}</print>
        <print>${description__es}</print>
    </sequence>
</process-definition>""", 
            "String\nnothing\nnothing\nnada")
    end

end

