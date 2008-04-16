
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'
require 'openwfe/participants/participants'


class FlowTest54 < Test::Unit::TestCase
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

            listen :to => "^channel_.$" do
                _print "ok"
            end

            sequence do

                _sleep "500"
                    #
                    # just making sure that the participant is evaluated
                    # after the listen [registration]

                participant :ref => "channel_z"
            end
        end
    end

    def test_0

        @engine.register_participant :channel_z, OpenWFE::NoOperationParticipant

        dotest Test0, "ok"
    end


    #
    # Test 1
    #

    class Test1 < OpenWFE::ProcessDefinition
        concurrence do

            listen :to => "^channel_.$", :where => "${f:f0} == alpha" do
                _print "alpha"
            end

            sequence do

                _sleep "500"
                    #
                    # just making sure that the participant is evaluated
                    # after the listen [registration]

                participant :ref => "channel_z"
                set :field => "f0", :value => "alpha"
                participant :ref => "channel_z"
            end
        end
    end

    def test_1

        log_level_to_debug

        @engine.register_participant :channel_z, OpenWFE::NoOperationParticipant

        dotest Test1, "alpha"
    end


    #
    # Test 2
    #

    class Test2 < OpenWFE::ProcessDefinition
        concurrence do

            listen :to => "^channel_.$" do
                #
                # upon apply by default

                _print "apply"
            end
            listen :to => "^channel_.$", :upon => "reply" do
                _print "reply"
            end

            sequence do

                _sleep "500"

                participant :ref => "channel_z"

                participant :ref => "channel_z"
                    #
                    # listeners are 'once' by default, check that
            end
        end
    end

    def test_2

        @engine.register_participant :channel_z, OpenWFE::NoOperationParticipant

        dotest Test2, [ "apply\nreply", "reply\napply" ]
    end


    #
    # Test 3 (moved to ft_54c_listen.rb)
    #


    #
    # Test 4
    #

    class Test4 < OpenWFE::ProcessDefinition
        concurrence do

            #listen :to => "^channel_.$", :rwhere => "self.fei.wfid == '${r:workitem.fei.wfid}'" do
            listen :to => "^channel_.$", :where => "${r:fei.wfid} == ${r:workitem.fei.wfid}" do
                _print "ok"
            end

            sequence do
                _sleep "500"
                participant :ref => "channel_z"
            end
        end
    end

    def test_4

        log_level_to_debug

        @engine.register_participant :channel_z do
            @tracer << "z\n"
        end

        dotest Test4, "z\nok"
    end


    #
    # Test 5
    #

    class Test5 < OpenWFE::ProcessDefinition
        concurrence do

            #listen :to => :channel_z do
            receive :on => :channel_z do
                _print "ok"
            end

            sequence do
                _sleep "500"
                channel_zz
                channel_z
            end
        end
    end

    def test_5

        @engine.register_participant :channel_z do
            @tracer << "z\n"
        end
        @engine.register_participant :channel_zz do
            @tracer << "zz\n"
        end

        dotest Test5, "zz\nok\nz"
    end


    #
    # Test 6 : merge => false (default)
    #

    class Test6 < OpenWFE::ProcessDefinition
        concurrence do

            sequence do

                set :field => "truck", :value => "v_truck_0"
                set :field => "car", :value => "v_car_0"

                listen :to => "^channel_.$" do
                    sequence do
                        _print "${f:truck}"
                        _print "${f:ferryboat}"
                        _print "${f:car}"
                    end
                end
            end

            sequence do

                _sleep "500"
                    #
                    # just making sure that the participant is evaluated
                    # after the listen [registration]

                set :field => "truck", :value => "v_truck_1"
                set :field => "ferryboat", :value => "v_ferryboat_1"

                participant :ref => "channel_z"
            end
        end
    end

    def test_6

        log_level_to_debug

        @engine.register_participant :channel_z, OpenWFE::NoOperationParticipant

        dotest Test6, "v_truck_1\nv_ferryboat_1"
    end


    #
    # Test 6b : merge => true
    #

    class Test6b < OpenWFE::ProcessDefinition
        concurrence do

            sequence do

                set :field => "truck", :value => "v_truck_0"
                set :field => "car", :value => "v_car_0"

                listen :to => "^channel_.$", :merge => true do
                    sequence do
                        _print "${f:truck}"
                        _print "${f:ferryboat}"
                        _print "${f:car}"
                    end
                end
            end

            sequence do

                _sleep "500"
                    #
                    # just making sure that the participant is evaluated
                    # after the listen [registration]

                set :field => "truck", :value => "v_truck_1"
                set :field => "ferryboat", :value => "v_ferryboat_1"

                participant :ref => "channel_z"
            end
        end
    end

    def test_6b

        log_level_to_debug

        @engine.register_participant :channel_z, OpenWFE::NoOperationParticipant

        dotest Test6b, "v_truck_1\nv_ferryboat_1\nv_car_0"
    end

end

