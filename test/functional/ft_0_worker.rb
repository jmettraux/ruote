
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtWorkerTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch_terminate

    #noisy

    pdef = Ruote.process_definition do
    end

    assert_trace pdef, ''

    #puts; logger.log.each { |e| p e }; puts
    assert_equal %w[ launch terminated ], logger.log.map { |e| e['action'] }
  end

  def test_stop_worker

    sleep 0.010 # warm up time

    assert_equal true, @engine.context.worker.running

    @engine.shutdown

    assert_equal false, @engine.context.worker.running

    pdef = Ruote.process_definition do; end

    @engine.launch(pdef)

    Thread.pass

    assert_equal 1, @engine.storage.get_many('msgs').size
  end
end

