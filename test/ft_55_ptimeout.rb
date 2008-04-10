
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'pending'
require 'openwfe/def'


class FlowTest55 < Test::Unit::TestCase
    include FlowTestBase
    include PendingJobsMixin

    #def setup
    #end

    #def teardown
    #end


    #
    # Test 0
    #

    class Test0 < OpenWFE::ProcessDefinition
        concurrence :count => 1 do
            sequence do
                participant :ref => "channel_z", :timeout => "1s"
                _print "cancelled?"
            end
            _print "concurrence done"
        end
    end

    def test_0

        #scheduler = @engine.get_scheduler
        #class << scheduler
        #    attr_reader :pending_jobs
        #end

        #log_level_to_debug

        @engine.register_participant :channel_z, OpenWFE::NullParticipant

        #require 'pp'; pp(scheduler.pending_jobs)
        assert_no_jobs_left

        dotest Test0, "concurrence done"

        #require 'pp'; pp(scheduler.pending_jobs)
        assert_no_jobs_left
    end

end

