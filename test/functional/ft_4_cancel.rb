
#
# Testing Ruote (OpenWFEru)
#
# Wed Jun  3 08:42:07 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtCancelTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cancel_process

    pdef = Ruote.process_definition do
      alpha
    end

    alpha = @engine.register_participant :alpha, Ruote::JoinableHashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    alpha.join

    ps = @engine.process_status(wfid)
    assert_equal 1, alpha.size

    assert_not_nil ps

    @engine.cancel_process(wfid)

    wait_for(wfid)
    ps = @engine.process_status(wfid)

    assert_nil ps
    assert_equal 0, alpha.size

    assert_equal 3, logger.log.select { |e| e[0] == :processes }.size
    assert_equal 3, logger.log.select { |e| e[1] == :cancel }.size
  end

  def test_cancel_expression

    pdef = Ruote.process_definition do
      sequence do
        alpha
        bravo
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::JoinableHashParticipant
    bravo = @engine.register_participant :bravo, Ruote::JoinableHashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    alpha.join

    wi = alpha.first

    @engine.cancel_expression(wi.fei)
    bravo.join

    assert_not_nil bravo.first
  end
end

