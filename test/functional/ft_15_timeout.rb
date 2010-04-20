
#
# testing ruote
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
        alpha :timeout => '1.1'
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:bravo)

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
    assert_equal 0, @engine.storage.get_many('schedules').size

    assert_not_nil bravo.first.fields['__timed_out__']
  end

  def test_cancel_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha :timeout => '1.1'
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(6)

    assert_equal 1, alpha.size

    @engine.cancel_expression(alpha.first.fei)

    wait_for(:bravo)

    assert_equal 0, alpha.size
    assert_equal 1, bravo.size
    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  def test_on_timeout_redo

    # with ruote-couch the 'cancel-process' operation gets overriden by
    # the timeout cancel...
    #
    # 0 20 ca * 20100320-bipopimita {}
    # 1 20   ca * 20100320-bipopimita  0 {"flavour"=>nil}
    # 2 20     ca * 20100320-bipopimita  0_0 {"flavour"=>"timeout"}
    # 3 20     ca * 20100320-bipopimita  0_0 {"flavour"=>nil, :pi=>"0!!20100320-bipopimita"}
    #
    # hence the multiple cancel at the end of the test

    pdef = Ruote.process_definition do
      alpha :timeout => '1.1', :on_timeout => 'redo'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(8)

    #logger.log.each { |e| p e['flavour'] }
    assert logger.log.select { |e| e['flavour'] == 'timeout' }.size >= 2

    3.times do
      Thread.pass
      @engine.cancel_process(wfid)
    end

    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end

  def test_on_timeout_cancel_nested

    pdef = Ruote.process_definition do
      sequence :timeout => '1.1', :on_timeout => 'timedout' do
        alpha
      end
      define 'timedout' do
        echo 'timed out'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal 'timed out', @tracer.to_s
    assert_equal 0, @engine.context.storage.get_many('expressions').size
    assert_equal 0, alpha.size
  end

  def test_on_timeout_error

    pdef = Ruote.process_definition do
      alpha :timeout => '1.1', :on_timeout => 'error'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

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
    assert_not_nil alpha.first.fields['__timed_out__']
  end

  def test_deep_on_timeout_error

    pdef = Ruote.process_definition do
      sequence :timeout => '1.1', :on_timeout => 'error' do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 0, alpha.size
    assert_equal 2, ps.expressions.size
  end

  def test_timeout_then_error

    pdef = Ruote.process_definition do
      sequence :timeout => '1.3' do
        toto
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(4)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  def test_timeout_at

    t = (Time.now + 2).to_s

    pdef = Ruote.process_definition do
      sequence :timeout => t do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    #wait_for(9)
    wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal 0, alpha.size
    assert_equal 0, @engine.storage.get_many('schedules').size
  end
end

