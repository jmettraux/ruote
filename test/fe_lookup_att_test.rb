
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Thu Nov  1 19:33:45 JST 2007
#

require 'test/unit'
require 'openwfe/expressions/flowexpression'


class FeLookupAttTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    def test_0

        attributes = { 
            "a" => true, 
            "b" => false,
        }
        fe = OpenWFE::FlowExpression.new_exp nil, nil, nil, nil, attributes

        assert_equal true, fe.lookup_boolean_attribute("a", nil)
        assert_equal true, fe.lookup_boolean_attribute(:a, nil)
        assert_equal true, fe.lookup_boolean_attribute("a", nil, false)
        assert_equal true, fe.lookup_boolean_attribute(:a, nil, false)
        assert_equal true, fe.lookup_boolean_attribute("a", nil, true)
        assert_equal true, fe.lookup_boolean_attribute(:a, nil, true)

        assert_equal false, fe.lookup_boolean_attribute("b", nil)
        assert_equal false, fe.lookup_boolean_attribute(:b, nil)
        assert_equal false, fe.lookup_boolean_attribute("b", nil, false)
        assert_equal false, fe.lookup_boolean_attribute(:b, nil, false)
        assert_equal false, fe.lookup_boolean_attribute("b", nil, true)
        assert_equal false, fe.lookup_boolean_attribute(:b, nil, true)

        # a fat but fast test
    end

end

