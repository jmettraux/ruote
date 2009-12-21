
#
# testing ruote
#
# Wed Aug 12 23:24:16 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'
require 'ruote/receiver'


class FtReceiverTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant
    include Ruote::LocalParticipant

    attr_accessor :wi

    def consume (workitem)

      @wi = workitem

      # no reply to the engine
    end
  end

  class MyReceiver < Ruote::Receiver
  end

  def test_my_receiver

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        alpha
        echo '.'
      end
    end

    alpha = @engine.register_participant 'alpha', MyParticipant.new

    receiver = MyReceiver.new(@engine.storage)

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 3, @engine.process(wfid).expressions.size

    receiver.receive(alpha.wi)

    wait_for(wfid)

    assert_nil @engine.process(wfid)

    rcv = logger.log.select { |e| e['action'] == 'receive' }.first
    assert_equal 'FtReceiverTest::MyReceiver', rcv['receiver']
  end

  def test_receiver_launch

    flunk
  end

  def test_engine_receive

    flunk
  end
end

