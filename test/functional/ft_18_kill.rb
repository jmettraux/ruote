
#
# testing ruote
#
# Sun Jul  5 22:56:06 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtKillTest < Test::Unit::TestCase
  include FunctionalBase

  def test_kill_process

    pdef = Ruote.process_definition do
      alpha
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    @dashboard.kill_process(wfid)

    wait_for(wfid)
    ps = @dashboard.process(wfid)

    assert_nil ps
    assert_equal 0, alpha.size

    assert_equal(
      1,
      logger.log.select { |e|
        e['action'] == 'cancel_process' &&
        e['flavour'] == 'kill'
      }.size)
  end

  def test_kill_process_with_source

    @dashboard.kill('20111121-nada', :source => 'y')

    @dashboard.wait_for(1)

    assert_equal 'y', @dashboard.context.logger.log.first['source']
  end

  def test_kill_does_not_trigger_on_cancel

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'catcher' do
        alpha
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    sto = @dashboard.register_participant :catcher, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    @dashboard.kill_process(wfid)

    wait_for(wfid)

    assert_equal 0, sto.size
  end

  def test_kill_expression_does_not_trigger_on_cancel

    pdef = Ruote.process_definition do
      sequence :on_cancel => 'catcher' do
        alpha
      end
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    sto = @dashboard.register_participant :catcher, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    @dashboard.kill_expression(sto.first.fei)

    wait_for(wfid)

    assert_equal 0, sto.size
  end

  def test_kill__expression

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    @dashboard.kill(wfid)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.process(wfid)

    assert_equal(
      1,
      logger.log.select { |e|
        e['action'] == 'cancel_process' &&
        e['flavour'] == 'kill'
      }.size)
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

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for(:alpha)

    @dashboard.kill(r['fei']) # fei as a Hash

    r = @dashboard.wait_for(:alpha)

    @dashboard.kill(Ruote.sid(r['fei'])) # fei as a String

    r = @dashboard.wait_for(:alpha)

    @dashboard.kill(Ruote::Workitem.new(r['workitem'])) # fei as workitem

    @dashboard.wait_for(wfid)

    assert_equal %w[ 0 1 2 ], @tracer.to_a

    assert_equal 6, logger.log.select { |e| e['flavour'] == 'kill' }.size
  end
end

