#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 15:41:44 JST 2006
#
# somewhere between Philippina and the Japan
#

require 'test/unit'

require 'openwfe/workitem'
require 'openwfe/engine/file_persisted_engine'
require 'openwfe/def'

require 'rutest_utils'


class RestartSleepTest < Test::Unit::TestCase

  #def setup
  #  @engine = $WORKFLOW_ENGINE_CLASS.new()
  #end

  #def teardown
  #end

  #
  # sleep tests

  class SleepDef < OpenWFE::ProcessDefinition
    def make
      process_definition :name => "rs0", :revision => "0" do
        sequence do
          _sleep :for => "10s"
          _print "after"
        end
      end
    end
  end

  def test_0
    dotest OpenWFE::FilePersistedEngine, SleepDef
  end
  def test_1
    dotest OpenWFE::CachedFilePersistedEngine, SleepDef
  end

  #
  # participant timeout tests

  class TimeoutDef < OpenWFE::ProcessDefinition
    sequence do
      nemo :timeout => "10s"
      _print "after"
    end
  end

  def test_timeout_0
    dotest OpenWFE::FilePersistedEngine, TimeoutDef
  end
  def test_timeout_1
    dotest OpenWFE::CachedFilePersistedEngine, TimeoutDef
  end

  TDEF = '''
<process-definition name="timeouttest" revision="1">
  <sequence>
    <participant ref="nemo" timeout="10s" />
    <print>after</print>
  </sequence>
</process-definition>
'''.strip

  def test_timeout_0b
    dotest OpenWFE::FilePersistedEngine, TDEF
  end

  protected

    def dotest (engine_class, def_class)

      #require 'fileutils'
      #FileUtils.remove_dir "work" if File.exist? "work"

      engine = new_engine engine_class

      #$OWFE_LOG.level = Logger::DEBUG

      li = OpenWFE::LaunchItem.new def_class

      engine.launch li

      sleep 1

      engine.stop

      $OWFE_LOG.warn "stopped the engine"

      old_engine = engine
      engine = new_engine engine_class

      #$OWFE_LOG.level = Logger::DEBUG

      $OWFE_LOG.warn "started the new engine"

      sleep 11
      #sleep 21

      s_old = old_engine.application_context["__tracer"].to_s
      s_now = engine.application_context["__tracer"].to_s

      #puts "__ s_old >>>#{s_old}<<<"
      #puts "__ s_now >>>#{s_now}<<<"

      $OWFE_LOG.level = Logger::INFO

      assert \
        (s_old == "" and s_now == "after"),
        "old : '#{s_old}'  /  new : '#{s_now}'  BAD for #{engine_class}"
    end

    def new_engine (engine_class)

      engine = engine_class.new :definition_in_launchitem_allowed => true

      tracer = Tracer.new
      engine.application_context["__tracer"] = tracer

      engine.register_participant :nemo, OpenWFE::NullParticipant

      #engine.reschedule
      engine.reload

      engine
    end

end

