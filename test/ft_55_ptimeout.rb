
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
    #log_level_to_debug

    @engine.register_participant :channel_z, OpenWFE::NullParticipant

    #p scheduler.at_job_count
    assert_no_jobs_left

    dotest Test0, "concurrence done"

    sleep 0.370 # give some time for the timeout unschedule

    #p scheduler.at_job_count
    #p scheduler.instance_variable_get(:@non_cron_jobs)
    assert_no_jobs_left
  end

end

