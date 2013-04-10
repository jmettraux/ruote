
#
# testing ruote
#
# Mon Jul 30 19:47:59 JST 2012
#

require File.expand_path('../base', __FILE__)

require 'ruote/observer'


class FtObserverTest < Test::Unit::TestCase
  include FunctionalBase

  class MyObserver < Ruote::Observer
    attr_reader :events
    def initialize(context)
      super
      @events = []
    end
    def on_msg_launch(msg)
      @events << [ 'launch', msg['wfid'] ]
    end
    def on_msg_terminated(msg)
      @events << [ 'terminated', msg['wfid'] ]
    end
  end

  def test_observer

    @dashboard.register 'alpha', Ruote::NoOpParticipant

    my_observer = MyObserver.new(@dashboard.context)
    @dashboard.add_service 'my_observer', my_observer
      #
      # using an instantiated service for easier testing...

    pdef =
      Ruote.define do
        alpha
      end

    wfid = @dashboard.launch(pdef)
    m = @dashboard.wait_for(wfid)

    assert_equal 'terminated', m['action']

    assert_equal(
      [ [ 'launch', wfid ], [ 'terminated', wfid ] ],
      my_observer.events)
  end

  class MyOtherObserver < Ruote::Observer
    attr_reader :wi
    def on_pre_msg_receive(msg)
      @wi =
        Ruote::Exp::FlowExpression.fetch(@context, msg['fei']).applied_workitem
    end
  end

  # For
  # https://groups.google.com/forum/#!topic/openwferu-users/_-sanN8B9q8
  #
  def test_on_receive_and_applied_workitem

    @dashboard.register 'alpha', Ruote::NoOpParticipant

    my_other_observer = MyOtherObserver.new(@dashboard.context)
    @dashboard.add_service 'my_other_observer', my_other_observer
      #
      # using an instantiated service for easier testing...

    wfid = @dashboard.launch(Ruote.define { alpha })
    m = @dashboard.wait_for(wfid)

    assert_equal Ruote::Workitem, my_other_observer.wi.class
    assert_equal '0_0', my_other_observer.wi.fei.expid
  end
end

