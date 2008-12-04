
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Dec  4 21:22:57 JST 2008
#

require 'flowtestbase'


class FlowTest95 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  # testing the 'error' expression

  class Test0 < OpenWFE::ProcessDefinition
    sequence :on_cancel => 'decommission' do
      alpha
    end
  end

  def test_0

    @engine.register_participant :alpha, OpenWFE::NullParticipant
      # receives workitems, discards them, does not reply to the engine

    @engine.register_participant :decommission do |workitem|
      @tracer << "decom\n"
    end

    fei = @engine.launch Test0

    sleep 0.350

    ps = @engine.process_status(fei)

    assert_equal 1, ps.expressions.size
    assert_equal 'alpha', ps.expressions.first.fei.expname

    @engine.cancel_process(fei)

    sleep 0.350

    assert_equal 'decom', @tracer.to_s

    assert_nil @engine.process_status(fei)
  end
end

