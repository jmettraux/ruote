
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'
require 'openwfe/participants/storeparticipants'


class FlowTest72 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end


    #
    # Test 0
    #

    class Test0 < OpenWFE::ProcessDefinition
        sequence do
            _set :variable => "/toto", :value => "${f:toto}"
            participant :alpha
        end
    end

    def test_0

        #log_level_to_debug

        sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

        li = OpenWFE::LaunchItem.new Test0
        li.toto = 'toto_zero'
        fei0 = launch li

        li = OpenWFE::LaunchItem.new Test0
        li.toto = 'toto_one'
        fei1 = launch li

        sleep 0.350

        wfids = @engine.lookup_processes('nada')
        assert_equal 0, wfids.size

        wfids = @engine.lookup_processes('toto')
        assert_equal 2, wfids.size
        assert wfids.include?(fei0.wfid)
        assert wfids.include?(fei1.wfid)

        wfids = @engine.lookup_processes('toto', 'smurf')
        assert_equal 0, wfids.size

        wfids = @engine.lookup_processes('toto', 'toto_.*')
        assert_equal 2, wfids.size

        wfids = @engine.lookup_processes('toto', Regexp.compile('toto_one'))
        assert_equal wfids, [ fei1.wfid ]

        # over.

        @engine.cancel_process fei0
        @engine.cancel_process fei1

        sleep 0.350
    end

end

