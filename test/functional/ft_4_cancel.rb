
#
# testing ruote
#
# Wed Jun  3 08:42:07 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cancel_process

    pdef = Ruote.process_definition do
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    ps = @engine.process(wfid)
    assert_equal 1, alpha.size

    assert_not_nil ps

    @engine.cancel_process(wfid)

    wait_for(wfid)
    ps = @engine.process(wfid)

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

    @engine.register_participant :alpha, Ruote::StorageParticipant
    sto = @engine.register_participant :bravo, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    assert_equal 1, sto.size

    wi = sto.first

    @engine.cancel_expression(wi.fei)
    wait_for(:bravo)

    assert_equal 1, sto.size
    assert_equal 'bravo', sto.first.participant_name
  end

  def test_cancel__process

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha, Ruote::NullParticipant

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    @engine.cancel(wfid)

    @engine.wait_for(wfid)

    assert_nil @engine.process(wfid)

    assert_equal 1, logger.log.select { |e| e['action'] == 'cancel_process' }.size
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

    @engine.register_participant :alpha, Ruote::NullParticipant

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(:alpha)

    @engine.cancel(r['fei']) # fei as a Hash

    r = @engine.wait_for(:alpha)

    @engine.cancel(Ruote.sid(r['fei'])) # fei as a String

    r = @engine.wait_for(:alpha)

    @engine.cancel(Ruote::Workitem.new(r['workitem'])) # fei as workitem

    @engine.wait_for(wfid)

    assert_equal %w[ 0 1 2 ], @tracer.to_a

    assert_equal 3, logger.log.select { |e| e['action'] == 'cancel' }.size
  end
end

