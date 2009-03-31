
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/expressions/expression_map'


class ExpmapTest < Test::Unit::TestCase

  def test_expmap_get_classes

    em = OpenWFE::ExpressionMap.new

    assert_equal(
      [
        OpenWFE::ParticipantExpression,
        OpenWFE::CronExpression,
        OpenWFE::WhenExpression,
        OpenWFE::WaitExpression,
        #OpenWFE::ReserveExpression,
        OpenWFE::ListenExpression,
        OpenWFE::TimeoutExpression,
        OpenWFE::HpollExpression,
        OpenWFE::Environment
      ],
      em.get_expression_classes(Rufus::Schedulable))
  end

  def test_lookingup_exp_classes

    em = OpenWFE::ExpressionMap.new

    #puts em.to_s

    assert_equal(
      em.get_class(:sequence),
      OpenWFE::SequenceExpression)

    assert_equal(
      em.get_class(:sequence),
      em.get_class('sequence'))

    assert_not_equal(
      em.get_class(:loop),
      em.get_class(:cursor))

    assert_equal(
      OpenWFE::DefineExpression,
      em.get_class('process-definition'),
      'class of "process-definition" should be DefineExpression')
    assert(
      em.is_definition?('process-definition'),
      'process-definition should be considered as a definition')
    assert(
      em.is_definition?(:process_definition),
      'process-definition should be considered as a definition (2)')
  end

  def test_workitem_holders

    assert_equal(
      [
        OpenWFE::ParticipantExpression,
        OpenWFE::CronExpression,
        OpenWFE::WhenExpression,
        OpenWFE::WaitExpression,
        OpenWFE::ReserveExpression,
        OpenWFE::FilterExpression,
        OpenWFE::ListenExpression,
        OpenWFE::TimeoutExpression,
        OpenWFE::HpollExpression
      ],
      OpenWFE::ExpressionMap.new.workitem_holders)
  end
end
