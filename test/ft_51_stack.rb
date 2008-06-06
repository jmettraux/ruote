
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest51 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  #COUNT = 400 :)
  #COUNT = 500 :(
  COUNT = 450
    #
    # before svn639, it broke with a too deep stack with a sequence
    # of 450 elements

  class TestCondition51a0 < OpenWFE::ProcessDefinition
    sequence do
      COUNT.times do
        toto
      end
      _print "${f:__result__}"
    end
  end

  def test_0

    count = 0

    @engine.register_participant :toto do |workitem|
      count += 1
      workitem.__result__ = count
    end

    dotest(TestCondition51a0, "#{COUNT}")
  end

end

