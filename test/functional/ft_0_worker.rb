
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/null_participant'


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
end

