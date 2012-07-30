
#
# testing ruote
#
# Thu Dec 24 18:05:39 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/util/process_subscriber'

class FtProcessObservingTest < Test::Unit::TestCase
  include FunctionalBase

  class MySubscriber < Ruote::ProcessObserver
    class << self
      attr_accessor :counter

      def reset
        @counter = {
          :launched => 0,
          :ended    => 0,
          :flunked  => 0,
          :canceled => 0,

          :step_total => 0,
        }
      end
    end

    def initialize(context, options)
      super
      MySubscriber.reset
    end

    def on_launch(wfid, workitem)
      MySubscriber.counter[:launched] += 1
    end

    def on_end(wfid, workitem)
      MySubscriber.counter[:ended] += 1
    end

    def on_error(wfid, workitem, error)
      MySubscriber.counter[:flunked] += 1
    end

    def on_cancel(wfid, workitem)
      MySubscriber.counter[:canceled] += 1
    end
  end

  def test_on_launch
    @dashboard.add_service('process_subscriber', MySubscriber)

    wfid = @dashboard.launch Ruote.define do; echo "hello"; end
    res  = @dashboard.wait_for(wfid)

    assert_equal 1, MySubscriber.counter[:launched]
  end

  def test_on_end
    @dashboard.add_service('process_subscriber', MySubscriber)

    wfid = @dashboard.launch Ruote.define do; echo "hello"; end
    res  = @dashboard.wait_for(wfid)

    assert_equal 1, MySubscriber.counter[:ended]
  end

  def test_on_error
    @dashboard.add_service('process_subscriber', MySubscriber)

    Ruote.register_participant :pinky do |wi|
      flunk(wi, "Narf!")
    end

    wfid = @dashboard.launch Ruote.define do; pinky; end
    res  = @dashboard.wait_for(wfid)

    assert_equal 1, MySubscriber.counter[:flunked]
  end

  def test_on_cancel
    @dashboard.add_service('process_subscriber', MySubscriber)

    Ruote.register_participant :brain do |wi|
      @dashboard.cancel(wi.fei.wfid)
    end

    wfid = @dashboard.launch Ruote.define do; brain; end
    res  = @dashboard.wait_for(wfid)

    assert_equal 1, MySubscriber.counter[:canceled]
  end

end
