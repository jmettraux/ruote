
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#


require 'flowtestbase'

require 'openwfe/def'
require 'openwfe/expool/journal'



class FlowTest32 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # TEST 0

    class TestDefinition0 < OpenWFE::ProcessDefinition
        #concurrence do
        sequence do
            #set :variable => "//toto", :value => "nada"
            participant :alpha
            bravo
        end
    end

    def test_journal_0

        @engine.application_context[:keep_journals] = true

        @engine.init_service "journal", OpenWFE::Journal

        @engine.register_participant(:alpha) do |wi|
            @tracer << "alpha\n"
        end
        @engine.register_participant(:bravo) do |wi|
            @tracer << "bravo\n"
        end

        #fei = dotest(TestDefinition0, "alpha\nbravo", 0.250)
        fei = dotest(TestDefinition0, "alpha\nbravo")

        journal_service = @engine.application_context["journal"]

        fn = journal_service.donedir + "/" + fei.wfid + ".journal"

        #puts journal_service.analyze fn

        #sleep(10)

        assert_equal @engine.get_expression_storage.size, 1

        journal_service.replay fn, 18
            #
            # replay at offset 18 without "refiring"
            #
            # flow waits

        sleep 0.350

        #puts
        #puts @engine.get_expression_storage.to_s
        #puts

        assert_equal @engine.get_expression_storage.size, 6

        journal_service.replay fn, 18, true
            #
            # replay at offset 18 with "refiring"
            #
            # flow resumes

        sleep 0.350

        assert_equal @engine.get_expression_storage.size, 1
    end

end

