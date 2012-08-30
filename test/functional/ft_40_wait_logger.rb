
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

    @dashboard.shutdown
    @dashboard.context.storage.purge!
  end

  def test_wait_logger

    @dashboard = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    sp = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition { alpha }

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(:alpha)
    assert_equal 'dispatch', r['action']

    sp.proceed(sp.first)

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
  end

  def test_wait_logger_seen

    @dashboard = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))
    #@dashboard.noisy = true

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

    @dashboard.add_service('counter', counter)

    pdef = Ruote.process_definition {}

    wfid = @dashboard.launch(pdef)

    counter.wait_for(2)

    seen = @dashboard.context.logger.instance_variable_get(:@seen)

    assert_equal %w[ launch terminated ], seen.collect { |m| m['action'] }

    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal 0, seen.size
  end

  def test_wait_for_goes_last

    @dashboard = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    log = []

    a = Object.new
    class << a
      attr_accessor :log
      def on_msg(msg)
        log << 'a'
      end
      def wait_for
        raise "never called anyway"
      end
    end
    a.log = log

    b = Object.new
    class << b
      attr_accessor :log
      def on_msg(msg)
        log << 'b'
      end
    end
    b.log = log

    @dashboard.add_service('a', a)
    @dashboard.add_service('b', b)

    #@dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define do
    end)
    @dashboard.wait_for(wfid)

    assert_equal %w[ b a b a ], log
  end

  def test_timeout

    @dashboard = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    wfid = @dashboard.launch(Ruote.define { stall })

    e = nil

    begin
      @dashboard.wait_for(wfid, :timeout => 1)
    rescue => e
    end

    assert_equal Ruote::LoggerTimeout, e.class
    assert_equal "waited for [\"#{wfid}\"], timed out after 1s", e.message
  end

  def _test_fancy_logging

    @dashboard = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    @dashboard.register :alpha do |workitem|
      context.storage.put_msg('decision_done', 'nada' => 'creep')
      sleep 0.200
    end

    @dashboard.noisy = true

    wfid = @dashboard.launch(Ruote.define { alpha })
    r = @dashboard.wait_for(wfid)
  end
end

