
#
# testing ruote
#
# Wed Aug 12 23:24:16 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtReceiverTest < Test::Unit::TestCase
  include FunctionalBase

  def setup

    super

    @pdef = Ruote.process_definition :name => 'test' do
      sequence do
        alpha
        echo '.'
      end
    end

    @alpha = @engine.register_participant 'alpha', MyParticipant.new
  end

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

    receiver = MyReceiver.new(@engine.storage)

    #noisy

    wfid = @engine.launch(@pdef)

    wait_for(:alpha)
    while @alpha.wi.nil? do
      Thread.pass
    end

    assert_equal 3, @engine.process(wfid).expressions.size

    receiver.receive(@alpha.wi)

    wait_for(wfid)

    assert_nil @engine.process(wfid)

    rcv = logger.log.select { |e| e['action'] == 'receive' }.first
    assert_equal 'FtReceiverTest::MyReceiver', rcv['receiver']
  end

  def test_engine_receive

    wfid = @engine.launch(@pdef)

    wait_for(:alpha)

    @engine.receive(@alpha.wi)

    wait_for(wfid)

    assert_nil @engine.process(wfid)

    rcv = logger.log.select { |e| e['action'] == 'receive' }.first
    assert_equal 'Ruote::Engine', rcv['receiver']
  end
end

