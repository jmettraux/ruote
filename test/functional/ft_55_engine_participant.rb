
#
# testing ruote
#
# Wed Jan 20 22:35:20 JST 2010
#
# between Denpasar and Singapore
#

require File.expand_path('../base', __FILE__)

require_json
Rufus::Json.detect_backend
require 'ruote'
require 'ruote/storage/fs_storage'
require 'ruote/participant'


class FtEngineParticipantTest < Test::Unit::TestCase
  #include FunctionalBase

  def setup

    @dir0 = "work_0_#{$$}_#{self.object_id}_#{Time.now.to_f}"
    @dir1 = "work_1_#{$$}_#{self.object_id}_#{Time.now.to_f}"

    @dashboard0 =
      Ruote::Engine.new(
        Ruote::Worker.new(
          Ruote::FsStorage.new(
            @dir0, 'engine_id' => 'engine0')))
    @dashboard1 =
      Ruote::Engine.new(
        Ruote::Worker.new(
          Ruote::FsStorage.new(
            @dir1, 'engine_id' => 'engine1')))

    @tracer0 = Tracer.new
    @dashboard0.add_service('tracer', @tracer0)

    @tracer1 = Tracer.new
    @dashboard1.add_service('tracer', @tracer1)

    @dashboard0.register_participant(
      'engine1',
      Ruote::EngineParticipant,
      'storage_class' => Ruote::FsStorage,
      'storage_path' => 'ruote/storage/fs_storage',
      'storage_args' => @dir1)
    @dashboard1.register_participant(
      'engine0',
      Ruote::EngineParticipant,
      'storage_class' => Ruote::FsStorage,
      'storage_path' => 'ruote/storage/fs_storage',
      'storage_args' => @dir0)
  end

  def teardown

    @dashboard0.shutdown
    @dashboard1.shutdown

  ensure
    FileUtils.rm_rf(@dir0)
    FileUtils.rm_rf(@dir1)
  end

  def noisy

    @dashboard0.context.logger.noisy = true
    @dashboard1.context.logger.noisy = true
    @dashboard1.context.logger.color = '32' # green
  end

  def test_as_participant

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        participant :ref => 'engine1', :pdef => 'subp'
        echo 'c'
      end
      define 'subp' do
        echo 'b'
      end
    end

    #noisy

    wfid = @dashboard0.launch(pdef)
    @dashboard0.wait_for(wfid)

    assert_equal "a\nc", @tracer0.to_s
    assert_equal "b", @tracer1.to_s
  end

  def test_as_subprocess

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        subprocess 'subp', :engine => 'engine1'
        echo 'c'
      end
      define 'subp' do
        echo 'b'
      end
    end

    #noisy

    wfid = @dashboard0.launch(pdef)
    @dashboard0.wait_for(wfid)

    assert_equal "a\nc", @tracer0.to_s
    assert_equal "b", @tracer1.to_s
  end

  def test_as_subprocess_2

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        subp :engine => 'engine1'
        echo 'c'
      end
      define 'subp' do
        echo 'b'
      end
    end

    #noisy

    wfid = @dashboard0.launch(pdef)
    @dashboard0.wait_for(wfid)

    assert_equal "a\nc", @tracer0.to_s
    assert_equal "b", @tracer1.to_s
  end

  def test_cancel_process

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        subp :engine => 'engine1'
        echo 'c'
      end
      define 'subp' do
        alpha
      end
    end

    #noisy

    alpha = @dashboard1.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard0.launch(pdef)

    @dashboard1.wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_nil alpha.first.fei.subid

    @dashboard0.cancel_process(wfid)
    @dashboard0.wait_for(wfid)

    #@dashboard0.wait_for(1) # since dispatch_cancel is asynchronous now
    sleep 0.777 # but well sometimes the dispatch is too fast

    assert_equal 0, alpha.size

    assert_equal 'a', @tracer0.to_s
    assert_equal '', @tracer1.to_s
  end

  def test_with_variables

    pdef = Ruote.process_definition do
      sequence do
        set 'v:v0' => 'b'
        echo 'a'
        subp :engine => 'engine1'
        echo 'c'
      end
      define 'subp' do
        echo '${r:engine_id}:${v:v0}'
      end
    end

    @dashboard1.context['ruby_eval_allowed'] = true
      # just for ${r:engine_id}

    #noisy

    wfid = @dashboard0.launch(pdef)
    @dashboard0.wait_for(wfid)

    assert_equal "a\nc", @tracer0.to_s
    assert_equal "engine1:b", @tracer1.to_s

    assert_nil @dashboard0.process(wfid)
  end

  def test_with_uri

    path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'pdef.xml'))

    pdef = Ruote.process_definition do
      participant :ref => 'engine1', :pdef => path
    end

    #noisy

    wfid = @dashboard0.launch(pdef)
    @dashboard0.wait_for(wfid)

    assert_equal "", @tracer0.to_s
    assert_equal "a\nb", @tracer1.to_s

    assert_nil @dashboard0.process(wfid)
  end

  def test_forget

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        participant :ref => 'engine1', :pdef => 'subp', :forget => true
        echo 'c'
      end
      define 'subp' do
        bravo
      end
    end

    bravo = @dashboard1.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard0.launch(pdef)
    @dashboard0.wait_for(wfid) # terminated
    sleep 0.100

    assert_equal [], @dashboard0.processes

    @dashboard1.wait_for(:bravo)

    bravo.proceed(bravo.first)

    @dashboard1.wait_for(wfid) # ceased

    assert_equal [], @dashboard0.processes
    assert_equal [], @dashboard1.processes
  end

  def test_replay_gone_engine_participant

    @dashboard1.unregister_participant('engine0')

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        participant :ref => 'engine1', :pdef => 'subp'
        echo 'c'
      end
      define 'subp' do
        echo 'b'
      end
    end

    #noisy

    wfid = @dashboard0.launch(pdef)
    @dashboard1.wait_for(wfid) # error

    errs = @dashboard1.process(wfid).errors

    assert_equal 1, errs.size

    # fix error cause

    @dashboard1.register_participant(
      'engine0',
      Ruote::EngineParticipant,
      'storage_class' => Ruote::FsStorage,
      'storage_path' => 'ruote/storage/fs_storage',
      'storage_args' => @dir0)

    # replay

    @dashboard1.replay_at_error(errs.first)

    @dashboard0.wait_for(wfid)

    assert_equal "a\nc", @tracer0.to_s
    assert_equal "b", @tracer1.to_s
  end
end

