
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'
require 'openwfe/worklist/storeparticipant'

require 'flowtestbase'


class FlowTest34 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # TEST 0

    class TestCancelWfid0 < ProcessDefinition
        #
        # so tiny a definition...
        #
        store_participant
    end

    def test_cancelwfid_0

        sp = @engine.register_participant(
            "store_participant", OpenWFE::HashParticipant)

        fei = @engine.launch(TestCancelWfid0)

        sleep 0.300

        @engine.cancel_process(fei.wfid)

        sleep 0.350

        l = @engine.list_processes

        assert_equal 0, l.size

        assert_equal 0, sp.size
            # check that participant got cancelled as well
    end

    def test_cancelwfid_1

        #log_level_to_debug

        sp = @engine.register_participant(
            "store_participant", OpenWFE::YamlParticipant)

        fei = @engine.launch(TestCancelWfid0)

        sleep 0.350

        @engine.cancel_process(fei.wfid)

        sleep 0.350

        assert_equal 0, @engine.get_process_stack(fei.wfid).size

        assert_equal 0, sp.size
            # check that participant got cancelled as well
    end

end

