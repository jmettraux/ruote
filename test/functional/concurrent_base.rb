
#
# Testing ruote
#
# Fri Dec  4 17:15:10 JST 2009
#

require File.join(File.dirname(__FILE__), 'base.rb')


module ConcurrentBase

  def setup

    @tracer = Tracer.new

    @storage = determine_storage(
      's_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ],
      's_tracer' => @tracer)))

    @engine0 = Ruote::Engine.new(Ruote::Worker.new(@storage), false)
    @engine1 = Ruote::Engine.new(Ruote::Worker.new(@storage), false)
      #
      # the 2 engines are set with run=false
  end

  def teardown

    @storage.purge!

    @engine0.shutdown
    @engine1.shutdown
  end
end

