
#
# testing ruote
#
# Sun Oct  4 00:14:27 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require_json
Rufus::Json.detect_backend rescue nil

require 'ruote/log/fs_history'
require 'ruote/part/no_op_participant'


class FtFsHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch

    pdef = Ruote.process_definition do
      alpha
      echo 'done.'
    end

    history = @engine.add_service(
      'history', 'ruote/log/fs_history', 'Ruote::FsHistory')

    @engine.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace("done.", pdef)
    wfid1 = assert_trace("done.\ndone.", pdef)

    sleep 0.100

    lines = File.readlines(Dir['work/log/*'].first)

    assert_equal 17, lines.size
    #lines.each { |l| puts l }

    h = @engine.context.history.by_process(wfid0)
    #h.each { |r| p r }
    assert_equal 8, h.size

    # testing record.to_h

    h = @engine.context.history.by_process(wfid1)
    #h.each { |r| p r }
    assert_equal 8, h.size

  ensure

    @engine.context.history.shutdown
    Dir['work/log/*'].each { |fn| FileUtils.rm(fn) }
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

    history = @engine.add_service(
      'history', 'ruote/log/fs_history', 'Ruote::FsHistory',
      'history_path' => 'work/log2')

    @engine.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace("done.", pdef)

    sleep 0.100

    h = @engine.context.history.by_process(wfid0)
    #h.each { |r| p r }
    assert_equal 11, h.size

  ensure

    @engine.context.history.shutdown
    Dir['work/log2/*'].each { |fn| FileUtils.rm(fn) }
  end

  def test_errors

    pdef = Ruote.process_definition :name => 'test' do
      nada
    end

    history = @engine.add_service(
      'history', 'ruote/log/fs_history', 'Ruote::FsHistory')

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    sleep 0.100

    h = @engine.context.history.by_process(wfid)
    #h.each { |r| p r }
    assert_equal 2, h.size

  ensure

    @engine.context.history.shutdown
    Dir['work/log/*'].each { |fn| FileUtils.rm(fn) }
  end

  def test_cancelling_failed_exp

    pdef = Ruote.process_definition :name => 'test' do
      nada
    end

    history = @engine.add_service(
      'history', 'ruote/log/fs_history', 'Ruote::FsHistory')

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    fei = @engine.process(wfid).errors.first.fei

    @engine.cancel_expression(fei)
    wait_for(wfid)

    sleep 0.100

    h = @engine.context.history.by_process(wfid)
    #h.each { |r| p r }
    assert_equal 5, h.size

  ensure

    @engine.context.history.shutdown
    Dir['work/log/*'].each { |fn| FileUtils.rm(fn) }
  end

  def test_history_date

    history = @engine.add_service(
      'history', 'ruote/log/fs_history', 'Ruote::FsHistory')

    FileUtils.mkdir(File.join(@engine.workdir, 'log')) rescue nil

    File.open(File.join('work', 'log', 'history_2009-10-08.json'), 'w') do |f|
      f.puts(%{
["!2009-10-08!12:33:27.835469",{"wfid":"20091224-beretsureto","tree":["define",{},[["alpha",{},[]],["echo",{"done.":null},[]]]],"workitem":{"fields":{},"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0"}},"variables":{},"type":"msgs","_id":"17619-2151883888-1261658007.83374","action":"launch","_rev":0,"put_at":"2009/12/24 12:33:27.833769 UTC"}]
["!2009-10-08!12:33:27.836787",{"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"tree":["participant",{"ref":"alpha"},[]],"parent_id":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0"},"variables":null,"workitem":{"fields":{"params":{"ref":"alpha"}},"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"participant_name":"alpha"},"type":"msgs","_id":"17619-2157823640-1261658007.83534","action":"apply","_rev":0,"put_at":"2009/12/24 12:33:27.835369 UTC"}]
["!2009-10-08!12:33:27.837098",{"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"participant_name":"alpha","workitem":{"fields":{"params":{"ref":"alpha"}},"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"participant_name":"alpha"},"for_engine_worker?":false,"type":"msgs","_id":"17619-2157823640-1261658007.83666","action":"dispatch","_rev":0,"put_at":"2009/12/24 12:33:27.836690 UTC"}]
      }.strip)
    end

    File.open(File.join('work', 'log', 'history_2009-10-31.json'), 'w') do |f|
      f.puts(%{
["!2009-10-31!12:33:27.835469",{"wfid":"20091224-beretsureto","tree":["define",{},[["alpha",{},[]],["echo",{"done.":null},[]]]],"workitem":{"fields":{},"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0"}},"variables":{},"type":"msgs","_id":"17619-2151883888-1261658007.83374","action":"launch","_rev":0,"put_at":"2009/12/24 12:33:27.833769 UTC"}]
["!2009-10-31!12:33:27.836787",{"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"tree":["participant",{"ref":"alpha"},[]],"parent_id":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0"},"variables":null,"workitem":{"fields":{"params":{"ref":"alpha"}},"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"participant_name":"alpha"},"type":"msgs","_id":"17619-2157823640-1261658007.83534","action":"apply","_rev":0,"put_at":"2009/12/24 12:33:27.835369 UTC"}]
["!2009-10-31!12:33:27.837098",{"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"participant_name":"alpha","workitem":{"fields":{"params":{"ref":"alpha"}},"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"participant_name":"alpha"},"for_engine_worker?":false,"type":"msgs","_id":"17619-2157823640-1261658007.83666","action":"dispatch","_rev":0,"put_at":"2009/12/24 12:33:27.836690 UTC"}]
["!2009-10-31!12:33:27.837961",{"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"workitem":{"fields":{},"fei":{"engine_id":"engine","wfid":"20091224-beretsureto","expid":"0_0"},"participant_name":"alpha"},"participant_name":"alpha","type":"msgs","_id":"17619-2159486252-1261658007.83719","action":"receive","_rev":0,"put_at":"2009/12/24 12:33:27.837235 UTC"}]
      }.strip)
    end

    assert_equal 3, @engine.context.history.by_date('2009-10-08').size
    assert_equal 4, @engine.context.history.by_date('2009-10-31').size

    assert_equal(
      [ Time.parse(Time.now.strftime('%Y-%m-%d')), Time.parse('2009-10-08') ],
      @engine.context.history.range)

  ensure

    @engine.context.history.shutdown
    Dir['work/log/*'].each { |fn| FileUtils.rm(fn) }
  end
end

