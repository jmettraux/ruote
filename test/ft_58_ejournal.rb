
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Fri Jun 29 23:12:53 JST 2007
#

require 'openwfe/def'

require 'flowtestbase'

require 'openwfe/engine/file_persisted_engine'
require 'openwfe/expool/errorjournal'



class FlowTest58 < Test::Unit::TestCase
    include FlowTestBase

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

    def test_0

        ejournal = @engine.get_error_journal

        @engine.register_participant(:alpha) do |wi|
            @tracer << "alpha\n"
        end

        #fei = dotest(Test0, "alpha", 0.500, true)
        li = LaunchItem.new Test0
        fei = @engine.launch li

        sleep 0.300

        assert File.exist?("work/ejournal/#{fei.parent_wfid}.ejournal") \
            if @engine.is_a?(FilePersistedEngine)

        errors = ejournal.get_error_log fei

        #require 'pp'; pp ejournal
        #puts "/// error journal of class #{ejournal.class.name}"

        assert_equal 1, errors.length

        assert ejournal.has_errors?(fei)
        assert ejournal.has_errors?(fei.wfid)

        # OK, let's fix the root and replay

        @engine.register_participant(:nada) do |wi|
            @tracer << "nada\n"
        end
        @engine.register_participant(:bravo) do |wi|
            @tracer << "bravo\n"
        end

        # fix done

        assert_equal "alpha", @tracer.to_s

        @engine.replay_at_error errors.first

        sleep 0.300

        assert_equal "alpha\nnada\nbravo", @tracer.to_s

        errors = ejournal.get_error_log fei

        assert_equal 0, errors.length

        assert ( ! ejournal.has_errors?(fei))
    end

end

