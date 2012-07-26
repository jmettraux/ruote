
#
# testing ruote
#
# Wed Aug 12 23:24:16 JST 2009
#

require File.expand_path('../base', __FILE__)

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

    @dashboard.register_participant 'alpha', MyParticipant
  end

  class MyParticipant
    include Ruote::LocalParticipant

    def consume(workitem)

      @context.stash[:wi] = workitem

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

    cid = @dashboard.context.object_id

    receiver = MyReceiver.new(@dashboard)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    receiver = MyReceiver.new(@dashboard.context)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    receiver = MyReceiver.new(@dashboard.worker)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    receiver = MyReceiver.new(@dashboard.storage)
    assert_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage

    @dashboard.storage.instance_variable_set(:@context, nil)
    receiver = MyReceiver.new(@dashboard.storage)
    assert_not_equal cid, receiver.context.object_id
    assert_not_nil receiver.context.storage
  end

  def test_my_receiver

    receiver = MyReceiver.new(@dashboard.context)

    wfid = @dashboard.launch(@pdef)

    wait_for(:alpha)
    while @dashboard.context.stash[:wi].nil? do
      Thread.pass
    end

    assert_equal 3, @dashboard.process(wfid).expressions.size

    receiver.receive(@dashboard.context.stash[:wi])

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)

    rcv = logger.log.select { |e| e['action'] == 'receive' }.first
    assert_equal 'FtReceiverTest::MyReceiver', rcv['receiver']
  end

  def test_engine_receive

    wfid = @dashboard.launch(@pdef)

    wait_for(:alpha)

    @dashboard.receive(@dashboard.context.stash[:wi])

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)

    rcv = logger.log.select { |e| e['action'] == 'receive' }.first
    assert_equal 'Ruote::Dashboard', rcv['receiver']
  end

  class MyOtherParticipant
    include Ruote::LocalParticipant
    def consume(workitem)
      @context.receiver.pass(workitem.to_h)
    end
  end
  class MyOtherReceiver < Ruote::Receiver
    def initialize(context, opts={})
      super(context, opts)
      @count = 0
    end
    def pass(workitem)
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

    class << @dashboard.context
      def receiver
        @rcv ||= MyOtherReceiver.new(engine)
      end
    end

    @dashboard.register_participant :alpha, MyOtherParticipant

    pdef = Ruote.process_definition do
      alpha
    end

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)
    err = ps.errors.first

    assert_equal 2, ps.expressions.size
    assert_equal 1, ps.errors.size
    assert_equal '#<RuntimeError: something went wrong>', err.message
    assert_equal String, err.msg['put_at'].class

    @dashboard.replay_at_error(err)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_nil ps
  end

  def test_receiver_fexp_and_wi

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    @dashboard.wait_for('dispatched')

    wi = @dashboard.storage_participant.first

    assert_equal wfid, wi.fei.wfid

    assert_equal wfid, @dashboard.fexp(wi).fei.wfid
    assert_equal wfid, @dashboard.fexp(wi.fei).fei.wfid
    assert_equal wfid, @dashboard.fexp(wi.fei.sid).fei.wfid
    assert_equal wfid, @dashboard.fexp(wi.fei.sid).h.applied_workitem['fei']['wfid']

    assert_equal wfid, @dashboard.workitem(wi).wfid
    assert_equal wfid, @dashboard.workitem(wi.fei).wfid
    assert_equal wfid, @dashboard.workitem(wi.fei.sid).wfid
  end

  class FlunkParticipant
    include Ruote::LocalParticipant

    # Since LocalParticipant extends ReceiverMixin, we can call #flunk
    #
    def on_workitem
      flunk(workitem, ArgumentError, 'out of order')
    end

    def on_cancel
      # ...
    end
  end

  class StringFlunkParticipant
    include Ruote::LocalParticipant

    # Since LocalParticipant extends ReceiverMixin, we can call #flunk
    #
    def on_workitem
      flunk(workitem, 'out of order')
    end

    def on_cancel
      # ...
    end
  end

  def test_flunk

    @dashboard.register :alpha, FlunkParticipant

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_equal 'ArgumentError', r['error']['class']
    assert_equal 'out of order', r['error']['message']
    assert_match __FILE__, r['error']['trace'].first
  end

  def test_string_flunk

    @dashboard.register :alpha, StringFlunkParticipant

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    r = @dashboard.wait_for(wfid)

    assert_equal 'error_intercepted', r['action']
    assert_equal 'RuntimeError', r['error']['class']
    assert_equal 'out of order', r['error']['message']
    assert_match __FILE__, r['error']['trace'].first
  end
end

