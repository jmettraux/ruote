
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require 'test/unit'
require 'openwfe/expressions/expressionmap'

#
# testing misc things
#

class ExpmapTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  def test_expmap_0

    em = OpenWFE::ExpressionMap.new

    #puts em.to_s

    assert_equal \
      em.get_class(:sequence),
      OpenWFE::SequenceExpression

    assert_equal \
      em.get_class(:sequence),
      em.get_class("sequence")

    assert_not_equal \
      em.get_class(:loop),
      em.get_class(:cursor)

    assert \
      em.get_class('process-definition') == OpenWFE::DefineExpression,
      "class of 'process-definition' should be DefineExpression"
    assert \
      em.is_definition?('process-definition'),
      "process-definition should be considered as a definition"
    assert \
      em.is_definition?(:process_definition),
      "process-definition should be considered as a definition (2)"
  end

end
