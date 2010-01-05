
#
# testing ruote
#
# Wed Jun  3 08:42:07 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cancel_process

    pdef = Ruote.process_definition do
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    wi = alpha.first

    @engine.cancel_expression(wi.fei)
    wait_for(:bravo)

    assert_not_nil bravo.first
  end
end

