
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest43 < Test::Unit::TestCase
  include FlowTestBase

  #def setup
  #end

  #def teardown
  #end


  #
  # Test 0
  #

  class TestCase43a0 < OpenWFE::ProcessDefinition
    def initialize (jump)
      super()
      @jump = jump
    end
    def make
      process_definition :name => "jump", :revision => "0" do
        sequence do
          set :field => "__cursor_command__", :value => "jump #{@jump}"
          cursor do
            _print "0"
            _print "1"
            _print "2"
          end
          _print "3"
        end
      end
    end
  end

  def test_0

    dotest TestCase43a0.new(1), "1\n2\n3"
  end

  def test_1

    dotest TestCase43a0.new(2), "2\n3"
  end

  def test_2

    dotest TestCase43a0.new(2000), "2\n3"
  end


  #
  # Test 3
  #

  class TestCase43a3 < OpenWFE::ProcessDefinition
    sequence do
      set :field => "__cursor_command__", :value => "jump 2"
      cursor do
        _print "0"
        skip :step => 2
        jump :step => 0
        _print "1"
      end
      _print "2"
    end
  end

  def test_3

    dotest TestCase43a3, "0\n1\n2"
  end

end

