
#
# Testing Ruote (OpenWFEru)
#
# Fri Jul 31 21:44:04 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class EftReserveTest < Test::Unit::TestCase
  include FunctionalBase

  def test_reserve

    pdef = Ruote.process_definition :name => 'test' do
      concurrence do
        reserve :mutex => 'a' do
          alpha
        end
        reserve 'a' do
          alpha
        end
      end
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_equal '0_0_0_0', alpha.first.fei.expid

    alpha.reply(alpha.first)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_equal '0_0_1_0', alpha.first.fei.expid

    alpha.reply(alpha.first)

    wait_for(wfid)
  end

  def test_cancel_reserve

    pdef = Ruote.process_definition :name => 'test' do
      concurrence do
        reserve :mutex => 'a' do
          alpha
        end
        reserve 'a' do
          alpha
        end
      end
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)
    exp = ps.expressions.find { |e| e.fei.expid == '0_0_0' }

    @engine.cancel_expression(exp.fei)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_equal '0_0_1_0', alpha.first.fei.expid

    alpha.reply(alpha.first)

    wait_for(wfid)
  end
end

