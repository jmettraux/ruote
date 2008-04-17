
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sat Jul  7 22:44:00 JST 2007 (tanabata)
#

require 'openwfe/def'
require 'openwfe/worklist/storeparticipant'

require 'flowtestbase'


class FlowTest59 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # TEST 0

    class Def59 < ProcessDefinition
        concurrence do
            store_a
            store_b
        end
    end

    def test_0

        sa = @engine.register_participant("store_a", OpenWFE::HashParticipant)
        sb = @engine.register_participant("store_b", OpenWFE::HashParticipant)

        fei = launch Def59

        sleep 0.350

        ps = @engine.process_statuses
        #puts ps

        assert_equal 2, ps[fei.wfid].expressions.size
        assert_equal 0, ps[fei.wfid].errors.size

        @engine.cancel_process fei
    end

    #
    # TEST 0b

    class Def59b < ProcessDefinition
        sequence do
            alpha
            bravo
        end
    end

    def test_0b

        a = @engine.register_participant :alpha, OpenWFE::HashParticipant
        b = @engine.register_participant :bravo, OpenWFE::HashParticipant

        fei = launch Def59b

        sleep 0.350

        ps = @engine.process_statuses
        #puts ps

        assert_equal 1, ps[fei.wfid].expressions.size
        assert_equal 0, ps[fei.wfid].errors.size

        @engine.cancel_process fei
    end

    #
    # TEST 1

    class Def59_1 < ProcessDefinition
        sequence do
            nada59_1
            alpha
        end
    end

    def test_1

        alpha = @engine.register_participant :alpha do
            # nothing
        end

        fei = launch Def59_1

        sleep 0.350

        ps = @engine.process_statuses
        #puts ps
        #puts ps[fei.wfid].errors

        assert_equal 1, ps[fei.wfid].expressions.size
        assert_equal 1, ps[fei.wfid].branches
        assert_equal 1, ps[fei.wfid].errors.size

        #puts
        #puts ps.to_s

        @engine.cancel_process fei.wfid
    end

    #
    # TEST 2

    class Def59c < ProcessDefinition
        sequence do
            bravo
            alpha
        end
    end

    def test_2

        a = @engine.register_participant :alpha, OpenWFE::HashParticipant
        b = @engine.register_participant :bravo, OpenWFE::HashParticipant

        feis = []
        feis << launch(Def59b)
        feis << launch(Def59b)
        feis << launch(Def59c)

        sleep 0.350

        assert_equal 3, @engine.list_processes(:wfname => "Def").size
        assert_equal 2, @engine.list_processes(:wfrevision => "59b").size
        assert_equal 1, @engine.list_processes(:wfrevision => "59c").size
        assert_equal 2, @engine.list_processes(:wfname => "Def", :wfrevision => "59b").size

        feis.each do |fei|
            @engine.cancel_process fei
        end

        sleep 0.350
    end

end

