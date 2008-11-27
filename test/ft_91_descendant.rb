
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Nov 27 13:42:11 JST 2008
#

require 'flowtestbase'


class FlowTest91 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      alpha
      sub0
    end
    define 'sub0' do
      bravo
    end
  end

  def test_0

    fei0 = nil
    fei1 = nil

    @engine.register_participant :alpha do |fexp, workitem|
      fei0 = fexp.fei.dup
    end
    @engine.register_participant :bravo do |fexp, workitem|
      fei1 = fexp.fei.dup
      sleep 60
    end

    @engine.launch(Test0)

    sleep 0.450

    #p fei0
    #p fei1

    fei0.expid = '0.0.1'

    bravo = @engine.get_expression_pool.fetch_expression(fei1)

    assert bravo.descendant_of?(fei0)
    assert bravo.descendant_of?(fei1) # self

    fei3 = fei1.dup
    fei3.expid = '0'

    assert bravo.descendant_of?(fei3)

    purge_engine
  end
end

