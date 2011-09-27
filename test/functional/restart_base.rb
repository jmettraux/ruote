
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
    @dashboard.shutdown
    @storage.purge!
  end

  protected

  def start_new_engine

    @storage = determine_storage(:persistent => true)

    @dashboard = Ruote::Engine.new(Ruote::Worker.new(@storage))

    #@tracer.clear

    @dashboard.add_service('tracer', @tracer)
  end
end

