
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'

require 'flowtestbase'


class FlowTest37 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    DEF0 = '''
<process-definition name="pnames" revision="0">
    <sequence>
        <participant ref="sps" />
        <participant ref="sps_1" />
    </sequence>
</process-definition>
'''.strip

    class TestPnames1 < OpenWFE::ProcessDefinition
        sequence do
            participant :ref => "sps"
            participant :ref => "sps_1"
        end
    end

    def test_pnames

        @engine.register_participant("sps") do |fexp, wi|
            @tracer << "sps\n"
        end
        @engine.register_participant("sps_1") do |fexp, wi|
            @tracer << "sps_1\n"
        end

        dotest(DEF0, "sps\nsps_1")

        dotest(TestPnames1, "sps\nsps_1", true)
    end

end

