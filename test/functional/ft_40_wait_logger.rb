
#
# testing ruote
#
# Tue Apr 20 12:32:44 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/storage_participant'


# Storage dependent WaitLogger tests. For storage independent test see
# test/unit/ut_3_wait_logger.rb
#
class FtWaitLoggerTest < Test::Unit::TestCase

  def teardown

    @engine.shutdown
    @engine.context.storage.purge!
  end

  def test_wait_logger

    @engine = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    sp = @engine.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition { alpha }

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(:alpha)
    assert_equal 'dispatch', r['action']

    sp.proceed(sp.first)

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  def test_wait_logger_seen

    @engine = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    counter = Object.new
    class << counter
      attr_reader :count
      def on_msg(msg)
        @count = (@count || 0) + 1
      end
      def wait_for(i)
        loop { sleep 0.100; break if (@count || 0) >= i }
      end
    end

    @engine.add_service('counter', counter)

    #@engine.noisy = true

    pdef = Ruote.process_definition { }

    wfid = @engine.launch(pdef)

    counter.wait_for(2)

    assert_equal 2, @engine.context.logger.instance_variable_get(:@seen).size

    r = @engine.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 0, @engine.context.logger.instance_variable_get(:@seen).size
  end
end

