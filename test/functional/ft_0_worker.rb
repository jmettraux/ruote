
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtWorkerTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch_terminate

    pdef = Ruote.process_definition do
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    #puts; logger.log.each { |e| p e }; puts
    assert_equal %w[ launch terminated ], logger.log.map { |e| e['action'] }
  end

  def test_stop_worker

    sleep 0.010 # warm up time

    assert_equal 'running', @dashboard.context.worker.state

    @dashboard.shutdown

    assert_equal 'stopped', @dashboard.context.worker.state

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

    assert_equal 0, @dashboard.storage.get_msgs.size
  end

  def test_stop_workers_not_enabled

    assert_raise(RuntimeError) do
      @dashboard.worker_state = 'stopped'
    end
  end

  def test_pause_workers

    @dashboard.context['worker_state_enabled'] = true

    pdef = Ruote.define do
      10.times { echo 'a' }
    end

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

    @dashboard.context['worker_state_enabled'] = true

    pdef = Ruote.define do
      10.times { echo 'a' }
    end

    assert_equal 'running', @dashboard.context.worker.state

    wfid = @dashboard.launch(pdef)

    @dashboard.worker_state = 'stopped'

    s = @tracer.to_a.size
    assert s < 10

    sleep 0.500

    assert @tracer.to_a.size < 10
    assert_equal s, @tracer.to_a.size

    assert_equal 'stopped', @dashboard.worker_state
    assert_equal 'stopped', @dashboard.context.worker.state
  end

  def test_worker_thread_ruote_worker

    assert_equal @dashboard.worker, @dashboard.worker.run_thread['ruote_worker']
  end

  def test_handle_step_error_and_error_handler

    $err = nil
    $msg = nil

    class << @dashboard.worker

      def handle_step_error(err, msg)
        $err = err
        $msg = msg
      end
    end

    class << @dashboard.storage

      alias original_put_msg put_msg

      def put_msg(action, details)
        raise 'out of order' if action == 'error_intercepted'
        original_put_msg(action, details)
      end
    end

    wfid = @dashboard.launch(Ruote.define do
      error 'pure fail'
    end)

    77.times { break if $msg; sleep 0.100 }

    assert_equal 'error_intercepted', $msg['action']
    assert_equal 'Ruote::ForcedError', $msg['error']['class']
    assert_equal 'pure fail', $msg['error']['message']
    assert_equal wfid, $msg['wfid']
    assert_equal '0_0', $msg['fei']['expid']

    assert_equal RuntimeError, $err.class
    assert_equal 'out of order', $err.message
  end
end

