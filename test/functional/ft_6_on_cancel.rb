
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
      tracer << "caught\n"
    end

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

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    @dashboard.cancel_process(wfid)

    wait_for(:bravo)

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [
          ["bravo", {}, []]]],
        ["sequence", {"on_cancel"=>"sub0"}, [
          ["alpha", {}, []]]]]],
      @dashboard.process(wfid).original_tree)
    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [
          ["bravo", {}, []]]],
        ["subprocess", {"_triggered"=>"on_cancel", "ref"=>"sub0"}, [
          ["define", {"sub0"=>nil}, [
            ["participant", {"ref"=>"bravo"}, []]]]]]]],
      @dashboard.process(wfid).current_tree)
  end

  def test_on_cancel_tree

    pdef = Ruote.process_definition :name => 'test' do
      set 'bar' => 'baz'
      sequence :on_cancel => [ 'sub0', { 'foo' => '${bar}' }, [] ] do
        alpha
      end
      define 'sub0' do
        echo 'foo:${v:foo}'
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 'foo:baz', @tracer.to_s
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

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('action' => 'apply', 'exp_name' => 'wait')

    @dashboard.cancel(@dashboard.process(wfid).expressions.last)

    @dashboard.wait_for('terminated')

    assert_equal "bailed\ndone.", @tracer.to_s
  end

  def test_on_cancel_is_not_triggered_by_on_error_undo

    pdef = Ruote.define do
      sequence :on_cancel => 'c', :on_error => 'undo' do
        echo 'n'
        error 'nada'
      end
      define 'c' do
        echo 'c'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ n ], @tracer.to_a
  end

  def test_on_cancel_is_triggered_by_on_error_cancel

    pdef = Ruote.define do
      sequence :on_cancel => 'c', :on_error => 'cancel' do
        echo 'n'
        error 'nada'
      end
      define 'c' do
        echo 'c'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ n c ], @tracer.to_a
  end

  #
  # 'cando'

  class MyBrokenParticipant
    include Ruote::LocalParticipant
    def self.reset
      @@seen = 0
    end
    def on_workitem
      if @@seen > 1
        reply
      else
        @@seen += 1
        fail 'broke'
      end
    end
    def on_cancel
    end
  end

  def test_on_cancel_is_triggered_by_on_error_cando

    MyBrokenParticipant.reset

    @dashboard.register :broken, MyBrokenParticipant

    pdef = Ruote.define do
      define 'c' do; echo 'c'; end
      sequence :on_cancel => 'c', :on_error => 'cando' do
        echo 'n'
        broken
      end
      echo 'z'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ n c n c n z ], @tracer.to_a
  end

  def test_on_error_cando_when_no_on_cancel

    MyBrokenParticipant.reset

    @dashboard.register :broken, MyBrokenParticipant

    pdef = Ruote.define do
      sequence :on_error => 'cando' do
        echo 'n'
        broken
      end
      echo 'z'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ n n n z ], @tracer.to_a
  end

  #
  # the "second take" feature

  def test_second_take

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.define do
      define 'sub0' do
        set '__on_cancel__' => 'redo'
      end
      sequence :on_cancel => 'sub0' do
        alpha
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('dispatched')

    exp = @dashboard.ps(wfid).expressions[1]
    @dashboard.cancel(exp)

    r = @dashboard.wait_for('dispatched')

    assert_equal 'alpha', r['participant_name']
  end
end

