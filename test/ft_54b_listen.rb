
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'
require 'openwfe/participants/participants'


class FlowTest54b < Test::Unit::TestCase
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
            listen :to => "^channel_.$", :upon => :reply
            _print "ok"
        end
    end

    def test_0

        #log_level_to_debug

        launch Test0

        sleep 0.350

        assert_equal @tracer.to_s, ""

        wi = OpenWFE::InFlowWorkItem.new
        wi.participant_name = "channel_z"

        r = @engine.reply wi
        assert r

        sleep 0.350

        #
        # "post test", checking that engine replies 'false' when
        # nobody consumed the message

        assert_equal @tracer.to_s, "ok"

        wi = OpenWFE::InFlowWorkItem.new
        wi.participant_name = "channel_unknown"

        r = @engine.reply wi
        assert (not r)
    end

end

