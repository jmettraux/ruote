
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Jan 13 14:41:33 JST 2009
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'


class FlowTest96 < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  def test_0

    test0 = OpenWFE.process_definition :name => 'ft96t0' do
      sub0
    end

    assert_equal(
      ["process-definition", {"name"=>"ft96t0"}, [["sub0", {}, []]]],
      test0)
  end

  #
  # Test 1
  #

  def test_1

    test1 = OpenWFE.process_definition :name => 'ft96t0' do
      sub0
      process_definition :name => 'sub0' do
        alpha
      end
    end

    assert_equal(
      ["process-definition", {"name"=>"ft96t0"}, [["sub0", {}, []], ["process-definition", {"name"=>"sub0"}, [["alpha", {}, []]]]]],
      test1)
  end

end

