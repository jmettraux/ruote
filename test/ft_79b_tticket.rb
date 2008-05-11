
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Thu Jan  3 23:05:37 JST 2008
#

require 'flowtestbase'


#
# The process definition under test
#
class TroubleTicket02 < OpenWFE::ProcessDefinition

  #
  # The root of the process
  #
  sequence do

    #
    # the first activity, customer support
    #
    cs :activity => "enter details"

    #
    # initiating the first step
    #
    step "qa", :desc => "reproduce problem"
  end

  #
  # The 'outputs' of the activities
  #

  # QA 'reproduce problem' outputs

  process_definition :name => "out:cannot_reproduce" do
    step "cs", :desc => "correct report"
  end
  process_definition :name => "out:known_solution" do
    finalsteps
  end
  process_definition :name => "out:duplicate" do
    step "qa", :desc => "verify"
  end
  process_definition :name => "out:reproduced" do
    step "dev", :desc => "resolution"
  end

  # Customer Support 'correct report' outputs

  process_definition :name => "out:submit" do
    step "qa", :desc => "reproduce problem"
  end
  process_definition :name => "out:give_up" do
    finalsteps
  end

  # QA 'verify' outputs

  process_definition :name => "out:qa_fixed" do
    finalsteps
  end
  process_definition :name => "out:not_fixed" do
    step "dev", :desc => "resolution"
  end

  # dev 'resolution' outputs

  process_definition :name => "out:dev_fixed" do
    step "qa", :desc => "verify"
  end

  set :var => "out:not_a_bug", :variable_value => "out:dev_fixed"
     # "not_a_bug" is an alias to "dev_fixed"

  # the final steps

  process_definition :name => "finalsteps" do
    concurrence do
      cs :activity => "communicate results"
      qa :activity => "audit"
    end
  end

end



class FlowTest79b < Test::Unit::TestCase
    include FlowTestBase

    def test_0

        dotest(
            [ "", "known_solution" ], # path
            [ "cs", "qa", "cs", "qa" ]) # expected trace
    end

    def test_1

        dotest(
            [ "", "cannot_reproduce", "give_up" ], # path
            [ "cs", "qa", "cs", "cs", "qa" ]) # expected trace
    end

    def test_2

        dotest(
            [ "", "reproduced", "dev_fixed", "qa_fixed" ], # path
            [ "cs", "qa", "dev", "qa", "cs", "qa" ]) # expected trace
    end

    def test_3

        dotest(
            [ "", "reproduced", "not_a_bug", "qa_fixed" ], # path
            [ "cs", "qa", "dev", "qa", "cs", "qa" ]) # expected trace
    end

    class TestParticipant 
        include OpenWFE::LocalParticipant

        attr_reader :trace

        def initialize (path)

            @path = path
            @trace = []
        end

        def consume (workitem)

            @trace << workitem.participant_name
                # Kilroy was here

            workitem.outcome = "out:#{@path.delete_at(0)}" if @path.size > 0
                # stating what should happen next (activity conclusion)

            reply_to_engine workitem
                # handing back the workitem to the engine
                # (please resume the process)
        end
    end

    def dotest (path, expected_trace)

        #log_level_to_debug

        p = TestParticipant.new path

        @engine.register_participant :cs, p
        @engine.register_participant :qa, p
        @engine.register_participant :dev, p

        fei = launch TroubleTicket02

        @engine.wait_for fei

        assert_equal expected_trace, p.trace

        sleep 0.400 # c tests reply too fast, have to wait a bit

        assert(
            (@engine.process_status(fei) == nil), 
            "process not over, check the [error] log")
    end
end

