
#
# testing ruote
#
# Tue Apr 20 12:32:44 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/storage_participant'


class FtWaitForTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitem

    pdef = Ruote.process_definition :name => 'my process' do
      alpha
    end

    sp = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal Ruote::Workitem, @engine.workitem("0_0!!#{wfid}").class
  end

  class MyParticipant
    include Ruote::LocalParticipant
    def initialize (opts)
    end
    def consume (workitem)
      sleep rand * 2
      reply_to_engine(workitem)
    end
  end

  def test_wait_for_empty

    pdef = Ruote.process_definition :name => 'my process' do
      alpha
    end

    @engine.register_participant :alpha, MyParticipant

    4.times do
      @engine.launch(pdef)
    end

    #noisy

    @engine.wait_for(:empty)

    assert_equal [], @engine.processes
  end

  def test_wait_for_multiple

    pdef0 = Ruote.process_definition { alpha }
    pdef1 = Ruote.process_definition { bravo }

    @engine.register_participant :alpha, MyParticipant

    #noisy

    wfids = []

    2.times { wfids << @engine.launch(pdef0) }
    2.times { wfids << @engine.launch(pdef1) }

    @engine.wait_for(*wfids)

    assert_equal 2, @engine.processes.size
  end

  def test_wait_for_inactive

    pdef0 = Ruote.process_definition { alpha }
    pdef1 = Ruote.process_definition { bravo }

    @engine.register_participant :alpha, MyParticipant

    #noisy

    wfids = []

    2.times { @engine.launch(pdef0) }
    2.times { wfids << @engine.launch(pdef1) }

    @engine.wait_for(:inactive)

    assert_equal wfids.sort, @engine.processes.collect { |ps| ps.wfid }.sort
  end

  def test_wait_for_multithreaded

    pdef = Ruote.process_definition { alpha }

    sp = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    seen = []

    Thread.new do
      @engine.wait_for(wfid)
      seen << 'this'
    end
    Thread.new do
      @engine.wait_for(wfid)
      seen << 'that'
    end

    @engine.wait_for(:alpha)

    sp.reply(sp.first)

    @engine.wait_for(wfid)

    sleep 0.100

    assert_equal %w[ that this ], seen.sort
    assert_equal [], @engine.context.logger.instance_variable_get(:@waiting)
  end
end

