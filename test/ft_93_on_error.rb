
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Nov 27 16:30:23 JST 2008
#

require 'flowtestbase'


class FlowTest93 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      _print '0'
      sequence :on_error => '' do
        alpha
        _print '1'
      end
      _print '2'
    end
  end

  def test_0

    @engine.register_participant :alpha do |fexp, workitem|
      raise 'break free !'
    end

    dotest Test0, "0\n2"
  end
end

