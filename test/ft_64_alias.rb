
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#

require 'openwfe/def'

require 'flowtestbase'


class FlowTest64a < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end


    #
    # TEST 0

    class Test0 < ProcessDefinition
        sequence do
            participant :bravo
            participant :abracadabra
        end
    end

    #def xxxx_0
    def test_0

        @engine.register_participant "a.*" do |workitem|
            @tracer << workitem.participant_name
            @tracer << "\n"
        end

        @engine.register_participant :bravo, AliasParticipant.new("alpha")

        dotest(Test0, "alpha\nabracadabra")
    end


    #
    # TEST 1

    class Test1 < ProcessDefinition
        sequence do
            set :v => "toto", :val => "elvis"
            toto
        end
    end

    def test_1

        #log_level_to_debug

        @engine.register_participant "elvis" do
            @tracer << "sivle"
        end

        dotest(Test1, "sivle")
    end


    #
    # TEST 2

    class Test2 < ProcessDefinition

        #
        # some aliases

        set :v => "alice", :val => "elvis"
        set :v => "bob", :val => "elvis"

        #
        # the body of the process

        sequence do
            alice
            bob
        end
    end

    def test_2

        #log_level_to_debug

        @engine.register_participant "elvis" do |workitem|
            @tracer << workitem.fei.expression_id
            @tracer << "\n"
        end

        dotest Test2, "0.2.0\n0.2.1"
    end

end

