
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

  def test_respark

    @dashboard.register 'alpha', Ruote::NoOpParticipant

    my_observer = MyObserver.new(@dashboard.context)
    @dashboard.add_service 'my_observer', my_observer
      #
      # using an instantiated service for easier testing...

    pdef = Ruote.define do
      alpha
    end

    wfid = @dashboard.launch(pdef)
    m = @dashboard.wait_for(wfid)

    assert_equal 'terminated', m['action']

    assert_equal(
      [ [ 'launch', wfid ], [ 'terminated', wfid ] ],
      my_observer.events)
  end
end

