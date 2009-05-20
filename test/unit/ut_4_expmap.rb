
#
# Testing Ruote
#
# Wed May 20 11:21:39 JST 2009
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'ruote/exp/expression_map'


class ExpMapTest < Test::Unit::TestCase

  def test_is_definition

    expmap = Ruote::ExpressionMap.new

    assert_equal true, expmap.is_definition?([ 'define', {}, [] ])
    assert_equal true, expmap.is_definition?([ 'process_definition', {}, [] ])
    assert_equal nil, expmap.is_definition?([ 'whatever', {}, [] ])
  end
end

