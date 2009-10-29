
#
# Testing Ruote (OpenWFEru)
#
# Sun Jun 28 16:45:57 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtTimeoutTest < Test::Unit::TestCase
  include FunctionalBase

  def test_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha :timeout => '1s'
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    sleep 1.5

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size
    assert_equal 1, logger.log.select { |e| e[2][:scheduler] == true }.size
    assert_equal 0, @engine.scheduler.jobs.size

    assert_not_nil bravo.first.fields['__timed_out__']
  end

  def test_cancel_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha :timeout => '2s'
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    sleep 1

    assert_equal 1, alpha.size

    @engine.cancel_expression(alpha.first.fei)

    #sleep 0.5
    wait_for(:bravo)

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size
    assert_equal 0, @engine.scheduler.jobs.size
  end

  def test_on_timeout_redo

    pdef = Ruote.process_definition do
      alpha :timeout => '500', :on_timeout => 'redo'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    sleep 1.6

    assert logger.log.select { |e| e[1] == :cancel }.size >= 2

    @engine.cancel_process(wfid)

    sleep 0.500

    assert_nil @engine.process(wfid)
  end

  def test_on_timeout_cancel_nested

    pdef = Ruote.process_definition do
      sequence :timeout => '500', :on_timeout => 'timedout' do
        alpha
      end
      define 'timedout' do
        echo 'timed out'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal 'timed out', @tracer.to_s
    assert_equal 0, @engine.expstorage.size
    assert_equal 0, alpha.size
  end

  def test_on_timeout_error

    pdef = Ruote.process_definition do
      alpha :timeout => '500', :on_timeout => 'error'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    err = ps.errors.first
    err.tree = [ 'alpha', {}, [] ]

    @engine.replay_at_error(err)
    wait_for(:alpha)

    assert_equal 1, alpha.size
  end

  def test_timeout_then_error

    pdef = Ruote.process_definition do
      sequence :timeout => '700' do
        toto
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    sleep 1.1

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 0, @engine.scheduler.jobs.size
  end
end

