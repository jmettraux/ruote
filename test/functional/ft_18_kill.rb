
#
# testing ruote
#
# Sun Jul  5 22:56:06 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtKillTest < Test::Unit::TestCase
  include FunctionalBase

  def test_kill_process

    pdef = Ruote.process_definition do
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    @engine.kill_process(wfid)

    wait_for(wfid)
    ps = @engine.process(wfid)

    assert_nil ps
    assert_equal 0, alpha.size

    assert_equal(
      1, logger.log.select { |e| e['action'] == 'kill_process' }.size)
  end

  def test_kill_does_not_trigger_on_cancel

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'catcher' do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    catcher = @engine.register_participant :catcher, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    @engine.kill_process(wfid)

    wait_for(wfid)

    assert_equal 0, alpha.size
    assert_equal 0, catcher.size
  end

  def test_kill_expression_does_not_trigger_on_cancel

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'catcher' do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    catcher = @engine.register_participant :catcher, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    @engine.kill_expression(alpha.first.fei)

    wait_for(wfid)

    assert_equal 0, alpha.size
    assert_equal 0, catcher.size
  end

  def test_kill__expression

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, Ruote::NullParticipant

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    @engine.kill(wfid)

    @engine.wait_for(wfid)

    assert_nil @engine.process(wfid)

    assert_equal 1, logger.log.select { |e| e['action'] == 'kill_process' }.size
  end

  def test_kill__process

    pdef = Ruote.process_definition do
      alpha
      echo '0'
      alpha
      echo '1'
      alpha
      echo '2'
    end

    @engine.register_participant :alpha, Ruote::NullParticipant

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(:alpha)

    @engine.kill(r['fei']) # fei as a Hash

    r = @engine.wait_for(:alpha)

    @engine.kill(Ruote.sid(r['fei'])) # fei as a String

    r = @engine.wait_for(:alpha)

    @engine.kill(Ruote::Workitem.new(r['workitem'])) # fei as workitem

    @engine.wait_for(wfid)

    assert_equal %w[ 0 1 2 ], @tracer.to_a

    assert_equal 6, logger.log.select { |e| e['flavour'] == 'kill' }.size
  end
end

