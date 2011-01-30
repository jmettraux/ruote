
#
# testing ruote
#
# Wed Jun  3 21:52:09 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtOnCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_on_cancel

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'catcher' do
        nemo
      end
    end

    nemo = @engine.register_participant :nemo, Ruote::StorageParticipant

    @engine.register_participant :catcher do
      @tracer << "caught\n"
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:nemo)

    @engine.cancel_process(wfid)
    wait_for(wfid)

    assert_equal 'caught', @tracer.to_s
  end

  def test_on_cancel_missing_handler

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'nada' do
        nemo
      end
    end

    nemo = @engine.register_participant :nemo, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:nemo)

    @engine.cancel_process(wfid)
    wait_for(wfid)

    ps = @engine.process(wfid)
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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal '', @tracer.to_s

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @engine.process(wfid)

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

    @engine.register_participant :alpha, Ruote::StorageParticipant
    sto = @engine.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    fei = @engine.process(wfid).expressions.find { |e|
      e.fei.expid == '0_1'
    }.fei

    @engine.cancel_expression(fei)

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

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @engine.cancel_process(wfid)

    wait_for(:bravo)

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [["bravo", {}, []]]],
        ["sequence", {"on_cancel"=>"sub0"}, [["alpha", {}, []]]]]],
      @engine.process(wfid).original_tree)
    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [["participant", {"ref"=>"bravo"}, []]]],
        ["sequence", {"on_cancel"=>"sub0", "_triggered"=>"on_cancel"}, [["alpha", {}, []]]]]],
      @engine.process(wfid).current_tree)
  end
end

