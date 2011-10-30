
#
# testing ruote
#
# Wed Jun  3 21:52:09 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtOnCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_on_cancel

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'catcher' do
        nemo
      end
    end

    nemo = @dashboard.register_participant :nemo, Ruote::StorageParticipant

    @dashboard.register_participant :catcher do
      @tracer << "caught\n"
    end

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:nemo)

    @dashboard.cancel_process(wfid)
    wait_for(wfid)

    assert_equal 'caught', @tracer.to_s
  end

  def test_on_cancel_missing_handler

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'nada' do
        nemo
      end
    end

    nemo = @dashboard.register_participant :nemo, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:nemo)

    @dashboard.cancel_process(wfid)
    wait_for(wfid)

    ps = @dashboard.process(wfid)
    assert_not_nil ps

    #logger.log.each { |e| puts e['action'] }
    assert_equal(
      1, logger.log.select { |e| e['action'] == 'error_intercepted' }.size)
  end

  def test_on_cancel_trigger_subprocess

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'decommission' do
        alpha
      end
      define 'decommission' do
        sequence do
          echo 'd0'
          echo 'd1'
        end
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal '', @tracer.to_s

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)

    assert_equal "d0\nd1", @tracer.to_s
  end

  def test_on_cancel_expression

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'decom' do
        alpha
      end
      define 'decom' do
        bravo
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    sto = @dashboard.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    fei = @dashboard.process(wfid).expressions.find { |e|
      e.fei.expid == '0_1'
    }.fei

    @dashboard.cancel_expression(fei)

    wait_for(:bravo)

    assert_equal 1, sto.size
  end

  def test_on_cancel_subprocess

    pdef = Ruote.process_definition :name => 'test' do
      sequence :on_cancel => 'sub0' do
        alpha
      end
      define 'sub0' do
        bravo
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    @dashboard.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    @dashboard.cancel_process(wfid)

    wait_for(:bravo)

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [["bravo", {}, []]]],
        ["sequence", {"on_cancel"=>"sub0"}, [["alpha", {}, []]]]]],
      @dashboard.process(wfid).original_tree)
    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [["participant", {"ref"=>"bravo"}, []]]],
        ["sequence", {"on_cancel"=>"sub0", "_triggered"=>"on_cancel"}, [["alpha", {}, []]]]]],
      @dashboard.process(wfid).current_tree)
  end

  def test_on_cancel_participant_resume

    pdef = Ruote.define do
      sequence do
        alpha :on_cancel => 'bail_out'
        echo 'done.'
      end
      define 'bail_out' do
        echo 'bailed'
      end
    end

    @dashboard.register :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    @dashboard.cancel(@dashboard.storage_participant.first)

    @dashboard.wait_for(wfid)

    assert_equal "bailed\ndone.", @tracer.to_s
  end

  def test_on_cancel_wait_resume

    pdef = Ruote.define do
      sequence do
        #alpha :on_cancel => 'bail_out'
        wait '1d', :on_cancel => 'bail_out'
        echo 'done.'
      end
      define 'bail_out' do
        echo 'bailed'
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(6)

    @dashboard.cancel(@dashboard.process(wfid).expressions.last)

    @dashboard.wait_for(11)

    assert_equal "bailed\ndone.", @tracer.to_s
  end
end

