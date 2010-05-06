
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

    # do not let the dispatch happen in its own thread, this makes
    # wait_for(:alpha) synchronous.
    #
    def do_not_thread

      true
    end
  end

  class MyReceiver < Ruote::Receiver
    attr_reader :context
  end

  def test_my_receiver_init

    cid = @engine.context.object_id

    receiver = MyReceiver.new(@engine)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    receiver = MyReceiver.new(@engine.context)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    receiver = MyReceiver.new(@engine.worker)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    receiver = MyReceiver.new(@engine.storage)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    @engine.storage.instance_variable_set(:@context, nil)
    receiver = MyReceiver.new(@engine.storage)
    assert_not_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage
  end

  def test_my_receiver

    receiver = MyReceiver.new(@engine.context)

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

  class MyOtherParticipant
    def initialize (receiver)
      @receiver = receiver
    end
    def consume (workitem)
      @receiver.pass(workitem.to_h)
    end
  end
  class MyOtherReceiver < Ruote::Receiver
    def initialize (context, opts={})
      super(context, opts)
      @count = 0
    end
    def pass (workitem)
      if @count < 1
        @context.error_handler.action_handle(
          'dispatch', workitem['fei'], RuntimeError.new('something went wrong'))
      else
        reply(workitem)
      end
      @count = @count + 1
    end
  end

  def test_receiver_triggered_dispatch_error

    receiver = MyOtherReceiver.new(@engine)

    @engine.register_participant :alpha, MyOtherParticipant.new(receiver)

    pdef = Ruote.process_definition do
      alpha
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    ps = @engine.process(wfid)
    err = ps.errors.first

    assert_equal 1, ps.errors.size
    assert_equal '#<RuntimeError: something went wrong>', err.message

    @engine.replay_at_error(err)

    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_nil ps
  end
end

