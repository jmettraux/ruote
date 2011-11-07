
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtWorkerTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch_terminate

    #noisy

    pdef = Ruote.process_definition do
    end

    assert_trace '', pdef

    #puts; logger.log.each { |e| p e }; puts
    assert_equal %w[ launch terminated ], logger.log.map { |e| e['action'] }
  end

  def test_stop_worker

    sleep 0.010 # warm up time

    assert_equal true, @dashboard.context.worker.running

    @dashboard.shutdown

    assert_equal false, @dashboard.context.worker.running

    pdef = Ruote.process_definition do; end

    @dashboard.launch(pdef)

    Thread.pass

    #assert_equal 1, @dashboard.storage.get_many('msgs').size
      # won't work with the latest ruote-redis implementations

    assert_equal 1, @dashboard.storage.get_msgs.size
  end

  def test_remaining_messages

    @dashboard.register_participant :alfred, Ruote::NullParticipant

    pdef = Ruote.process_definition do
    end

    assert_trace '', pdef

    sleep 0.300

    assert_equal [], @dashboard.storage.get_msgs
  end

  def test_pause_workers

    pdef = Ruote.define do
      10.times { echo 'a' }
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.worker_state = 'paused'

    s = @tracer.to_a.size
    assert s < 10

    sleep 0.500

    assert @tracer.to_a.size < 10
    assert_equal s, @tracer.to_a.size

    assert_equal 'paused', @dashboard.worker_state

    @dashboard.worker_state = 'running'

    @dashboard.wait_for('terminated')

    assert_equal 10, @tracer.to_a.size
    assert_equal 'running', @dashboard.worker_state
  end

  def test_stop_workers

    pdef = Ruote.define do
      10.times { echo 'a' }
    end

    #@dashboard.noisy = true

    assert_equal true, @dashboard.context.worker.running

    wfid = @dashboard.launch(pdef)

    @dashboard.worker_state = 'stopped'

    s = @tracer.to_a.size
    assert s < 10

    sleep 0.500

    assert @tracer.to_a.size < 10
    assert_equal s, @tracer.to_a.size

    assert_equal 'stopped', @dashboard.worker_state
    assert_equal false, @dashboard.context.worker.running
  end
end

