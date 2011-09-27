
#
# testing ruote
#
# Tue Apr 20 12:32:44 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/storage_participant'


class FtWaitForTest < Test::Unit::TestCase
  include FunctionalBase

  def test_workitem

    pdef = Ruote.process_definition :name => 'my process' do
      alpha
    end

    sp = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    r = wait_for(:alpha)

    assert_equal(
      Ruote::Workitem,
      @dashboard.workitem(Ruote.sid(r['fei'])).class)
  end

  class MyParticipant
    include Ruote::LocalParticipant
    def initialize(opts)
    end
    def consume(workitem)
      sleep rand * 2
      reply_to_engine(workitem)
    end
  end

  def test_wait_for_empty

    pdef = Ruote.process_definition :name => 'my process' do
      alpha
    end

    @dashboard.register_participant :alpha, MyParticipant

    4.times do
      @dashboard.launch(pdef)
    end

    #noisy

    @dashboard.wait_for(:empty)

    assert_equal [], @dashboard.processes
  end

  def test_wait_for_multiple

    pdef0 = Ruote.process_definition { alpha }
    pdef1 = Ruote.process_definition { bravo }

    @dashboard.register_participant :alpha, MyParticipant

    #noisy

    wfids = []

    2.times { wfids << @dashboard.launch(pdef0) }
    2.times { wfids << @dashboard.launch(pdef1) }

    @dashboard.wait_for(*wfids)

    assert_equal 2, @dashboard.processes.size
  end

  def test_wait_for_inactive

    pdef0 = Ruote.process_definition { alpha }
    pdef1 = Ruote.process_definition { bravo }

    @dashboard.register_participant :alpha, MyParticipant

    #noisy

    wfids = []

    2.times { @dashboard.launch(pdef0) }
    2.times { wfids << @dashboard.launch(pdef1) }

    @dashboard.wait_for(:inactive)

    assert_equal wfids.sort, @dashboard.processes.collect { |ps| ps.wfid }.sort
  end

  def test_wait_for_multithreaded

    pdef = Ruote.process_definition { alpha }

    sp = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    seen = []
    threads = []

    threads << Thread.new do
      @dashboard.wait_for(wfid)
      seen << 'this'
    end
    threads << Thread.new do
      @dashboard.wait_for(wfid)
      seen << 'that'
    end

    @dashboard.wait_for(:alpha)

    sp.proceed(sp.first)

    threads.each do |t|
      t.join
    end

    assert_equal %w[ that this ], seen.sort
    assert_equal [], @dashboard.context.logger.instance_variable_get(:@waiting)
  end
end

