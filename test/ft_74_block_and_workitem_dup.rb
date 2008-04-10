
#
# Testing OpenWFE
#
# Original bug report by Maarten Oelering
# John Mettraux at openwfe.org
#
# Thu Sep 13 17:46:20 JST 2007
#

require 'flowtestbase'


class FlowTest74 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # TEST 0

    def test_0

        engine.register_participant("part1") do |workitem|
            @tracer << "part1\n"
            # the last expression of the block evaluates to the workitem
            # remove this line or replace it with nil and it works again
            workitem
        end
        
        engine.register_participant("part3") do |workitem|
            @tracer << "part3\n"
        end
        
        engine.register_participant("part4") do |workitem|
            @tracer << "part4\n"
        end

        process = <<THE_END
<process-definition name="test" revision="0.1">
    <sequence>
        <part1/>
        <concurrence>
            <part3/>
            <part4/>
        </concurrence>
    </sequence>
</process-definition>
THE_END
        
        #log_level_to_debug

        dotest(
            process.strip,
            [ "part1\npart3\npart4", "part1\npart4\npart3" ])
    end

end

