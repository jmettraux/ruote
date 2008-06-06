#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Feb  7 15:26:57 JST 2008
#

require 'test/unit'

require 'openwfe/workitem'
require 'openwfe/engine/file_persisted_engine'
require 'openwfe/def'

require 'rutest_utils'


class RestartPauseTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  #
  # sleep tests

  class SleepDef < OpenWFE::ProcessDefinition
    _sleep :for => "1M"
  end

  def test_restart_0
    dotest OpenWFE::FilePersistedEngine, SleepDef
  end
  def test_restart_1
    dotest OpenWFE::CachedFilePersistedEngine, SleepDef
  end

  protected

    def dotest (engine_class, def_class)

      #require 'fileutils'
      #FileUtils.remove_dir "work" if File.exist? "work"

      engine = new_engine engine_class

      #$OWFE_LOG.level = Logger::DEBUG

      li = OpenWFE::LaunchItem.new def_class

      fei = engine.launch li

      sleep 0.350

      engine.pause_process fei.wfid

      sleep 0.350

      engine.stop

      $OWFE_LOG.warn "stopped the engine"

      old_engine = engine
      engine = new_engine engine_class

      #$OWFE_LOG.level = Logger::DEBUG

      $OWFE_LOG.warn "started the new engine"

      sleep 0.350

      assert_equal(
        true, engine.get_expression_pool.paused_instances[fei.wfid])

      engine.stop

      sleep 0.350
    end

    def new_engine (engine_class)

      engine = engine_class.new :definition_in_launchitem_allowed => true

      tracer = Tracer.new
      engine.application_context["__tracer"] = tracer

      #engine.register_participant :nemo, NullParticipant

      #engine.reschedule
      engine.reload

      engine
    end

end

