
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest52 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestObsParticipant52a0 < OpenWFE::ProcessDefinition
        participant :ref => :toto
    end

    def test_0

        @engine.get_expression_pool.add_observer :apply do |evt, fe, workitem|
            @tracer << "#{evt} #{fe.fei.expression_name}\n" \
                if fe.fei.expression_name == "participant"
        end
        @engine.get_expression_pool.add_observer :reply_to_parent do |evt, fe, workitem|
            @tracer << "#{evt} #{fe.fei.expression_name}\n" \
                if fe.fei.expression_name == "participant"
        end

        @engine.register_participant :toto do |workitem|
            @tracer << "toto\n"
        end

        dotest(
            TestObsParticipant52a0, 
            """
apply participant
toto
reply_to_parent participant
            """.strip)
    end


    #
    # Test 1
    #

    class TestObsParticipant52a1 < OpenWFE::ProcessDefinition
        sequence do
            toto
            sub0
        end
        process_definition :name => "sub0" do
        end
    end

    def test_1
        @engine.get_expression_pool.add_observer :apply do |evt, fe, workitem|
            @tracer << "#{evt} #{fe.fei.expression_name}\n"
        end
        @engine.register_participant :toto do
            #nothing
        end
        dotest(
            TestObsParticipant52a1,
            """
apply process-definition
apply sequence
apply toto
apply sub0
apply process-definition
            """.strip)
    end


    #
    # Test 2
    #

    class TestObsParticipant52a2 < OpenWFE::ProcessDefinition
        sequence do
            alpha
            bravo
        end
    end

    def test_2

        @engine.get_participant_map.add_observer :dispatch do |evt, msg, wi|
            @tracer << "#{evt} #{msg} #{wi.fei.expression_name}\n"
        end

        @engine.register_participant :alpha do |workitem|
            @tracer << "alpha\n"
        end
        @engine.register_participant :bravo do |workitem|
            @tracer << "bravo\n"
        end

        dotest(
            TestObsParticipant52a2, 
            """
dispatch before_consume alpha
alpha
dispatch after_consume alpha
dispatch before_consume bravo
bravo
dispatch after_consume bravo
            """.strip)
    end

end

