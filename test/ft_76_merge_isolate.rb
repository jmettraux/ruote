
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest76 < Test::Unit::TestCase
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
      concurrence :merge_type => :isolate do
        set :field => "y", :value => "y0"
        set :field => "y", :value => "y1"
        set :field => "y", :value => "y2"
      end
      catcher
    end
  end

  def test_0

    do_the_test Test0
  end

  #
  # Test 1
  #

  class Test1 < OpenWFE::ProcessDefinition
    sequence do
      concurrent_iterator(
        :on_value => "0, 1, 2",
        :to_field => "f",
        :merge_type => :isolate
      ) do
        set :field => "y", :value => "y${f:f}"
      end
      catcher
    end
  end

  def test_1
    do_the_test Test1
  end

  protected

    def do_the_test (definition)

      #log_level_to_debug

      workitem = nil

      engine.register_participant :catcher do |wi|
        workitem = wi
      end

      dotest definition, ""

      #puts
      #puts workitem.to_s

      3.times do |i|
        assert_equal "y#{i}", workitem.lookup_attribute("#{i}.y")
      end
        #
        # 3 lines replaced by 3 lines :)
    end

end

