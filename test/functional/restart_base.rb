
#
# testing ruote
#
# Wed Jul  1 23:27:49 JST 2009
#

module RestartBase

  def setup

    @tracer = Tracer.new

    FileUtils.rm_rf(
      File.expand_path(File.join(File.dirname(__FILE__), %w[ .. .. work ])))
  end

  def teardown
  end

  protected

  def start_new_engine

    ac = {}

    ac[:s_tracer] = @tracer
    #ac[:ruby_eval_allowed] = true
    #ac[:definition_in_launchitem_allowed] = true

    engine_class = determine_engine_class(ac)
    engine_class = Ruote::FsPersistedEngine if engine_class == Ruote::Engine
    @engine = engine_class.new(ac)

    @engine.add_service(:s_logger, Ruote::TestLogger)
  end
end

