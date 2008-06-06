
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Sat Feb 16 19:07:42 JST 2008
#

require 'flowtestbase'


class FlowTest82 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end

  #
  # Test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      participant :ref => "toto"
      subprocess :ref => "Test", :unless => "${f:count} == 3"
    end
  end

  def test_0

    #log_level_to_debug

    @engine.register_participant :toto do |workitem|

      if workitem.attributes['count'] != nil
        workitem.count = workitem.count + 1
      else
        workitem.count = 0
      end

      @tracer << workitem.count.to_s
    end

    dotest Test0, "0123"
  end

end

