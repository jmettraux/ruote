
#
# Testing Ruote (OpenWFEru)
#
# Sun Oct  4 00:14:27 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/log/fs_history'
require 'ruote/part/no_op_participant'


class FtHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch

    pdef = Ruote.process_definition do
      alpha
      echo 'done.'
    end

    history = @engine.add_service(:s_history, Ruote::FsHistory)

    @engine.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace(pdef, "done.")
    wfid1 = assert_trace(pdef, "done.\ndone.")

    sleep 0.010

    lines = File.readlines(Dir['work/log/*'].first)

    assert_equal 8, lines.size
    #lines.each { |l| puts l }

    h = @engine.history.by_process(wfid0)
    #h.each { |r| p r }
    assert_equal 4, h.size
    assert_equal Time, h.first.at.class

    fei = h[1].fei
    assert_equal Ruote::FlowExpressionId, fei.class
    assert_equal wfid0, fei.wfid
    assert_equal '0_0', fei.expid
    assert_equal 'engine', fei.engine_id

    # testing record.to_h

    r = @engine.history.by_process(wfid1).first

    assert_equal 'launch', r.to_h['event']
  end

  def test_subprocess

    pdef = Ruote.process_definition :name => 'test', :revision => '3' do
      sequence do
        sub0
        echo 'done.'
      end
      define 'sub0' do
        alpha
      end
    end

    @engine.add_service(:s_history, Ruote::FsHistory)

    @engine.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace(pdef, "done.")

    sleep 0.100

    #dump_history

    h = @engine.history.by_process(wfid0)
    #h.each { |r| p r }
    assert_equal 5, h.size
  end

  def test_errors

    pdef = Ruote.process_definition :name => 'test' do
      nada
    end

    @engine.add_service(:s_history, Ruote::FsHistory)

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    sleep 0.010

    #dump_history

    h = @engine.history.by_process(wfid)
    #h.each { |r| p r }
    assert_equal 2, h.size
  end

  def test_cancelling_failed_exp

    pdef = Ruote.process_definition :name => 'test' do
      nada
    end

    @engine.add_service(:s_history, Ruote::FsHistory)

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    fei = @engine.process(wfid).errors.first.fei

    @engine.cancel_expression(fei)
    wait_for(wfid)

    h = @engine.history.by_process(wfid)
    #h.each { |r| p r }
    assert_equal 3, h.size
  end

  def test_history_date

    @engine.add_service(:s_history, Ruote::FsHistory)

    FileUtils.mkdir(File.join(@engine.workdir, 'log')) rescue nil

    File.open(File.join(
      @engine.workdir, 'log', 'engine_history_2009-10-08.txt'), 'w'
    ) do |f|
      f.puts(%{
2009-10-08 16:52:37.751683 20091008-bihomugiso ps launch name=test
2009-10-08 16:52:37.782714 20091008-bihomugiso er s_expression_pool 0_0 RuntimeError unknown expression 'nada'
2009-10-08 16:52:38.525532 20091008-bijesejuno ps launch name=test
2009-10-08 16:52:38.533304 20091008-bijesejuno er s_expression_pool 0_0 RuntimeError unknown expression 'nada'
2009-10-08 16:52:39.525532 20091008-bojesejuna ps launch name=test
2009-10-08 16:52:39.533304 20091008-bojesejuna er s_expression_pool 0_0 RuntimeError unknown expression 'nada'
      }.strip)
    end

    File.open(File.join(
      @engine.workdir, 'log', 'engine_history_2009-10-31.txt'), 'w'
    ) do |f|
      f.puts(%{
2009-10-31 16:52:14.017324 20091009-totsugubi ps launch name=test
2009-10-31 16:52:14.026024 20091009-totsugubi er s_expression_pool 0_0 RuntimeError unknown expression 'nada'
2009-10-31 16:52:36.027944 20091009-bigehimodi ps launch name=test
2009-10-31 16:52:36.037019 20091009-bigehimodi er s_expression_pool 0_0 RuntimeError unknown expression 'nada'
      }.strip)
    end

    assert_equal 6, @engine.history.by_date('2009-10-08').size
    assert_equal 4, @engine.history.by_date('2009-10-31').size

    assert_equal(
      [ Time.parse('2009-10-31'), Time.parse('2009-10-08') ],
      @engine.history.range)
  end

  protected

  def dump_history

    lines = File.readlines(Dir['work/log/*'].first)
    puts; lines.each { |l| puts l }
  end
end

