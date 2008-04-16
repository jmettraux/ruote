
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'
require 'openwfe/participants/participants'


class FlowTest54c < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end


    #
    # Test 0
    #

    class Test0 < OpenWFE::ProcessDefinition
        concurrence do

            listen :to => "^channel_.$", :once => false do
                _print "apply"
            end

            sequence do
                _sleep "300"
                participant :ref => "channel_z"
                channel_z
            end
        end
    end

    def test_0

        @engine.register_participant :channel_z do
            @tracer << "z\n"
        end

        #log_level_to_debug

        outputs = [
            %w{ z apply z apply }.join("\n"),
            %w{ z z apply apply }.join("\n")
        ]

        dotest Test0, outputs, 0.850, true
    end

    #
    # Test 1
    #

    class Test1 < OpenWFE::ProcessDefinition
        concurrence do
            listen :to => "channel9", :once => false do
                listen9
            end
            sequence do
                _sleep "300"
                channel9
            end
        end
    end

    def test_1

        log_level_to_debug

        @engine.register_participant "channel9", OpenWFE::NullParticipant
        @engine.register_participant "listen9", OpenWFE::NullParticipant

        fei = @engine.launch Test1

        sleep 0.700

        #puts @engine.get_expression_storage
        assert_equal 8, @engine.get_expression_storage.size

        #puts @engine.get_expression_storage

        @engine.cancel_process fei

        sleep 0.350

        #puts @engine.get_expression_storage
        assert_equal 1, @engine.get_expression_storage.size
    end

end

