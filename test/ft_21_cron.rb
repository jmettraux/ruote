
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest21 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestDefinition0 < OpenWFE::ProcessDefinition
        cron :tab => "* * * * *", :name => "cron" do
            participant :cron_event
        end
    end

    #
    # this one tests whether a cron event is removed when his process
    # terminates, as should be.
    #
    def test_0

        #log_level_to_debug

        @engine.register_participant(:cron_event) do
            puts "    :(    cron_event at #{Time.now.to_s}"
            @tracer << "cron_event"
        end

        #puts "start at #{Time.now.to_s}"
        #dotest TestDefinition0, "", 62

        fei = launch TestDefinition0

        sleep 0.350

        assert_equal "", @tracer.to_s
        assert_not_nil @engine.process_status(fei)

        @engine.cancel_process fei

        sleep 0.350

        assert_nil @engine.process_status(fei)
        assert_equal 1, @engine.get_expression_storage.size
    end

    #
    # Test 1
    #

    class TestDefinition1 < OpenWFE::ProcessDefinition
        concurrence :count => 1 do
            cron :every => "1s500" do
                participant :cron_event
            end
            _sleep "7s"
        end
    end

    def test_1

        #log_level_to_debug

        @engine.register_participant(:cron_event) do
            @tracer << "x"
        end

        dotest TestDefinition1, [ "xxxx", "xxxxx" ]
    end

end

