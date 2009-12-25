
#
# testing ruote
#
# Wed Jul  1 23:27:49 JST 2009
#

module RestartBase

  def setup
    @tracer = Tracer.new
  end

  def teardown
    @engine.shutdown
    @storage.purge!
  end

  protected

  def start_new_engine

    @storage = determine_storage(
      's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ],
      :persistent => true)

    @engine = Ruote::Engine.new(Ruote::Worker.new(@storage))

    #@tracer.clear

    @engine.add_service('tracer', @tracer)
  end
end

