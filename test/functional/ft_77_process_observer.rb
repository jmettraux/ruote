#
# Testing process observers
#
# Made in Germany
# by Hartog de Mik
#

require File.expand_path('../base', __FILE__)
require 'ruote/util/process_observer'

class FtProcessObservingTest < Test::Unit::TestCase
  include FunctionalBase

  def test_on_launch

    observer = Class.new(Ruote::ProcessObserver) do

      class << self
        attr_accessor :started
      end

      def on_launch(wfid)
        self.class.started = true
      end

      def on_error_intercepted(wfid, info)
        ex = info[:error]
        STDERR.puts "#{ex.class.name}: #{ex.message}"
        STDERR.puts "\t#{ex.backtrace.join("\n\t")}"
      end
    end

    @dashboard.add_service('start_observer', observer)

    wfid = @dashboard.launch Ruote.define do; echo "hello"; end
    res  = @dashboard.wait_for(wfid)

    assert_equal true, observer.started
  end

  def test_on_sub_launch

    observer = Class.new(Ruote::ProcessObserver) do

      class << self
        attr_accessor :info, :launches
      end

      def on_launch(wfid, info)
        self.class.info = info.dup
        self.class.launches += 1
      end
    end
    observer.launches = 0

    @dashboard.add_service('sub_launch_observer', observer)

    pdef = Ruote.define do
      sequence do
        alpha
      end

      define :alpha do
        echo "I am the sub"
      end
    end

    wfid = @dashboard.launch pdef
    @dashboard.wait_for(wfid)

    assert_not_nil observer.info
    assert_equal 2, observer.launches
    assert_equal true, observer.info[:child]
    assert_not_nil observer.info[:pdef]
  end

  def test_on_end

    observer = Class.new(Ruote::ProcessObserver) do

      class << self
        attr_accessor :stopped
      end

      def on_terminated(wfid)
        self.class.stopped = true
      end
    end

    @dashboard.add_service('stop_server', observer)

    wfid = @dashboard.launch Ruote.define do; echo "hello"; end
    res  = @dashboard.wait_for(wfid)

    assert_equal true, observer.stopped
  end

  def test_on_error

    observer = Class.new(Ruote::ProcessObserver) do

      class << self
        attr_accessor :flunked, :info
      end

      def on_error_intercepted(wfid, info)
        self.class.flunked = true
        self.class.info = info
      end
    end

    @dashboard.add_service('observer', observer)

    @dashboard.register_participant :pinky do |wi|
      raise "hell"
    end

    wfid = @dashboard.launch Ruote.define() { pinky }
    res  = @dashboard.wait_for(wfid)

    assert_equal true, observer.flunked
    assert_not_nil observer.info
    assert_not_nil observer.info[:error]
    assert_equal "hell", observer.info[:error].message
  end

  def test_on_cancel

    observer = Class.new(Ruote::ProcessObserver) do

      class << self
        attr_accessor :canceled
      end

      def on_cancel(wfid)
        self.class.canceled = true
      end
    end

    @dashboard.add_service('cancel_observer', observer)

    @dashboard.register_participant :brain do |wi|
      context.dashboard.cancel(wi.wfid)
    end

    wfid = @dashboard.launch Ruote.define() { brain }
    res  = @dashboard.wait_for(wfid)

    assert_equal true, observer.canceled
  end

  def test_on_error_intercepted

    observer = Class.new(Ruote::ProcessObserver) do

      class << self
        attr_accessor :wfid
        attr_accessor :info
      end

      def on_error_intercepted(wfid, info)
        self.class.wfid = wfid
        self.class.info = info
      end
    end

    @dashboard.add_service('observer', observer)

    wfid = @dashboard.launch(Ruote.define { nada })
    @dashboard.wait_for(wfid)

    assert_equal(wfid, observer.wfid)
    assert_equal(RuntimeError, observer.info[:error].class)
    assert_equal(wfid, observer.info[:workitem].wfid)
  end

  def test_observer_discards_any_error_it_endures

    observer = Class.new(Ruote::ProcessObserver) do

      class << self
        attr_accessor :flunked
      end

      def on_launch(wfid)
        raise "Sit still! I'm trying to kill you!"
      end

      def on_error_intercepted(wfid)
        self.class.flunked = true
      end
    end

    @dashboard.add_service('observer', observer)

    wfid = @dashboard.launch Ruote.define do; echo('hi'); end
    res  = @dashboard.wait_for(wfid)

    assert_equal nil, observer.flunked
  end
end

