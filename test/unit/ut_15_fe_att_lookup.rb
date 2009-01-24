
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Nov  1 19:33:45 JST 2007
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/expressions/flowexpression'


class FeAttLookupTest < Test::Unit::TestCase

  def test_0

    attributes = {
      'a' => true,
      'b' => false,
      'A' => 'a, b, c,d,${e},f',
      'B' => [ 1, 2, 3, '${a}' ]
    }

    fe = OpenWFE::FlowExpression.new_exp nil, nil, nil, nil, attributes

    class << fe
      def lookup_variable (varname)
        varname * 2
      end
    end

    assert_equal true, fe.lookup_boolean_attribute('a', nil)
    assert_equal true, fe.lookup_boolean_attribute(:a, nil)
    assert_equal true, fe.lookup_boolean_attribute('a', nil, false)
    assert_equal true, fe.lookup_boolean_attribute(:a, nil, false)
    assert_equal true, fe.lookup_boolean_attribute('a', nil, true)
    assert_equal true, fe.lookup_boolean_attribute(:a, nil, true)

    assert_equal false, fe.lookup_boolean_attribute('b', nil)
    assert_equal false, fe.lookup_boolean_attribute(:b, nil)
    assert_equal false, fe.lookup_boolean_attribute('b', nil, false)
    assert_equal false, fe.lookup_boolean_attribute(:b, nil, false)
    assert_equal false, fe.lookup_boolean_attribute('b', nil, true)
    assert_equal false, fe.lookup_boolean_attribute(:b, nil, true)

    assert_equal %w{ a b c d ee f }, fe.lookup_array_attribute('A', nil)
    assert_equal [ 1, 2, 3, 'aa' ], fe.lookup_array_attribute('B', nil)

    # a fat but fast test
  end

end

