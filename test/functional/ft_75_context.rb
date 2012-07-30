
#
# testing ruote
#
# Mon Jul 30 17:27:22 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtContextTest < Test::Unit::TestCase

  def teardown

    @dashboard.shutdown
    @dashboard.context.storage.purge!
  end

  def test_wait_for_goes_last

    @dashboard = Ruote::Engine.new(Ruote::Worker.new(determine_storage({})))

    log = []

    c = Object.new
    class << c
      attr_accessor :log
      def on_msg(msg)
        log << 'c'
      end
      def wait_for # it's a waiter
        raise 'never called anyway'
      end
    end
    c.log = log

    b = Object.new
    class << b
      attr_accessor :log
      def on_msg(msg)
        log << 'b'
      end
    end
    b.log = log

    a = Object.new
    class << a
      attr_accessor :log
      def on_msg(msg)
        log << 'a'
      end
    end
    a.log = log

    @dashboard.add_service('c', c) # waiter
    @dashboard.add_service('b', b) # observer
    @dashboard.add_service('a', a) # observer

    wfid = @dashboard.launch(Ruote.define do
    end)
    @dashboard.wait_for(wfid)

    assert_equal %w[ a b c a b c ], log
  end
end

