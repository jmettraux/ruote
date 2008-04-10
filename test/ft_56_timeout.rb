
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'pending'
require 'openwfe/def'


class FlowTest56 < Test::Unit::TestCase
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
        sequence do
            _timeout :after => "1s" do
                sequence do
                    _print "ok"
                    _sleep "2s"
                    _print "not ok"
                end
            end
            _print "done"
        end
    end

    def test_0

        assert_no_jobs_left

        dotest Test0, "ok\ndone"

        sleep 0.350 # skip one scheduler beat

        #s = @engine.get_scheduler
        #class << s
        #    attr_reader :pending_jobs
        #end
        #p s.pending_jobs.collect { |j| [ j.job_id, j.class.name ] }

        assert_no_jobs_left
    end

end

