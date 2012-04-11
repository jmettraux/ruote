
#
# testing ruote
#
# Wed Jun  3 08:42:07 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cancel_process

    pdef = Ruote.process_definition do
      alpha
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    ps = @dashboard.process(wfid)
    assert_equal 1, alpha.size

    assert_not_nil ps

    @dashboard.cancel_process(wfid)

    wait_for(wfid)
    ps = @dashboard.process(wfid)

    assert_nil ps
    assert_equal 0, alpha.size

    #puts; logger.log.each { |e| p e['action'] }; puts
    assert_equal 1, logger.log.select { |e| e['action'] == 'cancel_process' }.size
    assert_equal 2, logger.log.select { |e| e['action'] == 'cancel' }.size
  end

  def test_cancel_expression

    pdef = Ruote.process_definition do
      sequence do
        alpha
        bravo
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    sto = @dashboard.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    assert_equal 1, sto.size

    wi = sto.first

    @dashboard.cancel_expression(wi.fei)
    wait_for(:bravo)

    assert_equal 1, sto.size
    assert_equal 'bravo', sto.first.participant_name
  end

  def test_cancel__process

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    @dashboard.cancel(wfid)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.process(wfid)

    assert_equal(
      1,
      logger.log.select { |e| e['action'] == 'cancel_process' }.size)
  end

  def test_cancel_process_with_source

    @dashboard.cancel('20111121-nada', :source => 'x')

    @dashboard.wait_for(1)

    assert_equal 'x', logger.log.first['source']
  end

  def test_cancel__expression

    pdef = Ruote.process_definition do
      alpha
      echo '0'
      alpha
      echo '1'
      alpha
      echo '2'
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(:alpha)

    @dashboard.cancel(r['fei']) # fei as a Hash

    r = @dashboard.wait_for(:alpha)

    @dashboard.cancel(Ruote.sid(r['fei'])) # fei as a String

    r = @dashboard.wait_for(:alpha)

    @dashboard.cancel(Ruote::Workitem.new(r['workitem'])) # fei as workitem

    @dashboard.wait_for(wfid)

    assert_equal %w[ 0 1 2 ], @tracer.to_a

    assert_equal 3, logger.log.select { |e| e['action'] == 'cancel' }.size
  end

  def test_cancel_rebound

    pdef = Ruote.define do
      stall
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for('apply')

    @dashboard.cancel(wfid)
    r = @dashboard.wait_for('terminated')

    assert_equal 'cancel', r['flavour']
  end

  def test_kill_rebound

    pdef = Ruote.define do
      stall
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for('apply')

    @dashboard.kill(wfid)
    r = @dashboard.wait_for('terminated')

    assert_equal 'kill', r['flavour']
  end

  def test_cancel_limited_rebound

    pdef = Ruote.define do
      stall
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for('apply')

    exp = @dashboard.process(wfid).expressions.last

    @dashboard.cancel(exp)
    r = @dashboard.wait_for('terminated')

    assert_equal nil, r['flavour']
  end
end

