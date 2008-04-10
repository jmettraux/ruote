#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 15:41:44 JST 2006
#

require 'rubygems'

require 'test/unit'

require 'fileutils'

require 'openwfe/workitem'
require 'openwfe/engine/file_persisted_engine'
require 'openwfe/def'

require 'rutest_utils'


class RestartCronTest < Test::Unit::TestCase

    #def setup
    #    @engine = $WORKFLOW_ENGINE_CLASS.new()
    #end

    def teardown
        FileUtils.rm_rf 'work'
    end

    # test 0

    class RestartDefinition0 < OpenWFE::ProcessDefinition
        cron :tab => "* * * * *", :name => "//mycron" do
            cron_event_restart
        end
    end

    def test_0

        dotest RestartDefinition0

        assert_equal(
            4, @engine.get_expression_storage.size,
            "\n\n" + @engine.get_expression_storage.to_s)
    end

    # test 1

    class RestartDefinition1 < OpenWFE::ProcessDefinition
        concurrence do
            cron :tab => "* * * * *", :name => "mycron" do
                cron_event_restart
            end
            participant :ref => "nada"
        end
    end

    def test_1

        dotest RestartDefinition1

        assert_equal(
            6, @engine.get_expression_storage.size,
            "\n\n" + @engine.get_expression_storage.to_s)
    end

    protected

        def dotest (definition)

            @engine = new_engine

            feis = []

            participant = lambda do |wi|
                feis << wi.fei.dup
            end
            @engine.register_participant :cron_event_restart, &participant
            @engine.register_participant :nada, OpenWFE::NullParticipant

            fei = @engine.launch definition

            sleep 60

            @engine.stop

            assert_equal 1, @engine.get_scheduler.cron_job_count
            assert_equal 1, feis.size

            assert_equal(
                ".0", 
                feis[0].expid[-2, 2], 
                "not ending with .0 : >#{feis[0].expid}<")
            assert_equal(
                fei.wfid, 
                feis[0].wfid)

            #puts "___restarting to new engine"

            #old_engine = @engine
            new_engine

            @engine.register_participant :cron_event_restart, &participant
            @engine.register_participant :nada, OpenWFE::NullParticipant

            @engine.reload
                #
                # very important

            sleep 60

            assert_equal(
                1, @engine.get_scheduler.cron_job_count, "wrong cron job count")

            @engine.stop

            assert_equal 2, feis.size
            assert_equal feis[0].wfid, feis[1].wfid

            assert feis[0].expid[-1, 1].to_i < feis[1].expid[-1, 1].to_i
        end

        def new_engine

            @engine = OpenWFE::FilePersistedEngine.new
            #engine = OpenWFE::CachedFilePersistedEngine.new

            #$OWFE_LOG.level = Logger::DEBUG
        end

end

