
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Sun Mar 23 13:26:15 JST 2008
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest21b < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestDefinition0 < OpenWFE::ProcessDefinition
        cron :tab => "* * * * * *", :name => "cron" do
            participant :cron_event
        end
    end

    #
    # this one tests whether a cron event is removed when his process
    # terminates, as should be.
    #
    def test_0

        #log_level_to_debug

        counter = 0

        @engine.register_participant(:cron_event) do
            counter += 1
        end

        #puts "start at #{Time.now.to_s}"
        #dotest TestDefinition0, "", 62

        fei = launch TestDefinition0

        sleep 0.350

        assert_equal "", @tracer.to_s
        assert_not_nil @engine.process_status(fei)

        sleep 3

        @engine.pause_process fei.wfid

        assert_equal 3, counter

        sleep 3

        assert_equal 3, counter
        assert_equal 0, @engine.process_status(fei).errors.size

        @engine.resume_process fei.wfid

        sleep 3

        assert_equal 6, counter

        @engine.cancel_process fei.wfid

        sleep 0.350

        assert_nil @engine.process_status(fei)
    end

end

