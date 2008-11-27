
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Nov 27 15:17:23 JST 2008
#

require 'flowtestbase'


class FlowTest92 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      set :var => '//toto', :val => 0
      set :var => 'toto', :val => 1
      sub0
    end
    define 'sub0' do
      sequence do
        set :var => 'toto', :val => 2
        alpha
      end
    end
  end

  def test_0

    @engine.register_participant :alpha do |fexp, workitem|
      @tracer << fexp.lookup_variable_stack('toto').inspect
    end

    dotest Test0, '[2, 1, 0]'
  end
end

