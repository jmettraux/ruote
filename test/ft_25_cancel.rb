
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest25 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  def test_cancel_0

    #log_level_to_debug

    dotest(
      '''
<process-definition name="25_cancel" revision="0">
  <sequence>
    <print>before</print>
    <cancel-process/>
    <print>after</print>
  </sequence>
</process-definition>
      '''.strip,
      "before",
      0.400)
  end


  #
  # TEST 1

  class TestDefinition1 < OpenWFE::ProcessDefinition
    def make
      _process_definition :name => "25_cancel", :revision => "1" do
        _sequence do
          _print "before"
          _cancel_process
          _print "after"
        end
      end
    end
  end

  def test_1

    dotest(TestDefinition1, 'before', 0.500)
  end


  #
  # TEST 2

  class TestDefinition2 < OpenWFE::ProcessDefinition
    def make
      _process_definition :name => "25_cancel", :revision => "2" do
        _sequence do
          _print "before"
          _cancel_process :if => "false"
          _print "after"
        end
      end
    end
  end

  def test_2

    dotest TestDefinition2, "before\nafter"
  end

end

