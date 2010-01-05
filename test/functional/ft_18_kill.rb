
#
# testing ruote
#
# Sun Jul  5 22:56:06 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


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
end

