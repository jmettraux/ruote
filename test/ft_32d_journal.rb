
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/def'

require 'flowtestbase'

require 'openwfe/expool/journal'



class FlowTest32d < Test::Unit::TestCase
    include FlowTestBase
    include JournalTestBase

    #def teardown
    #end

    #def setup
    #end


    #
    # TEST 0

    class Test0 < ProcessDefinition
        sequence do
            participant :alpha
            participant :nada
            participant :bravo
        end
    end

    #def xxxx_0
    def test_0

        @engine.application_context[:keep_journals] = true

        @engine.init_service "journal", Journal

        @engine.register_participant(:alpha) do |wi|
            @tracer << "alpha\n"
        end

        class << get_journal
            public :flush_buckets
        end

        li = LaunchItem.new Test0
        fei = launch li

        sleep 0.500

        get_journal.flush_buckets

        assert_equal 1, get_error_count(fei.wfid)

        @engine.register_participant(:nada) do |wi|
            @tracer << "nada\n"
        end
        @engine.register_participant(:bravo) do |wi|
            @tracer << "bravo\n"
        end

        assert_equal @tracer.to_s, "alpha"

        get_journal.replay_at_last_error fei.wfid

        sleep 1.0

        assert_equal "alpha\nnada\nbravo", @tracer.to_s 

        fn = get_journal.workdir + "/" + fei.wfid + ".journal"
        assert (not File.exist?(fn))
    end

end

