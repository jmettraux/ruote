
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# since Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/utils'


class LookupAttributeTest < Test::Unit::TestCase

  def test_0

    l0 = [
      {'name'=>'companyA','DunsNr' => 'JGE4753'},
      {'name'=>'companyB','DunsNr' => 'ZUTE8555'},
      {'name'=>'companyC','DunsNr' => 'GTI6775'},
      {'name'=>'companyD','DunsNr' => 'XUE6755'}
    ]
    h0 = { 'supplierList' => l0 }

    do_lookup_test(
      h0, 'supplierList', l0)
    do_lookup_test(
      h0, 'supplierList.1', {'name'=>'companyB','DunsNr' => 'ZUTE8555'})
    do_lookup_test(
      h0, 'supplierList.1.DunsNr', 'ZUTE8555')

    do_has_attribute_test(
      h0, 'supplierList.1.DunsNr', true)
    do_has_attribute_test(
      h0, 'supplierList.1.Whatever', false)
    do_has_attribute_test(
      h0, 'supplierList.whatever', false)
    do_has_attribute_test(
      h0, 'whatever', false)

    h1 = { 'supplierList' => l0.to_s }
    do_lookup_test(
      h1, 'supplierList.1.DunsNr', nil)

    do_has_attribute_test(
      nil, 'whatever', false)
    do_has_attribute_test(
      {}, 'whatever', false)
    do_has_attribute_test(
      [], 'whatever', false)
    do_has_attribute_test(
      'string',  'whatever', false)

    do_has_attribute_test(
      [ nil, nil ], '1.name', false)
  end

  def test_1

    h = { '0' => [ 'a', 'A' ], '1' => { 'b' => 'B'} }

    do_lookup_test(h, '0', [ 'a', 'A' ])
    do_lookup_test(h, '1.b', 'B')
    do_has_attribute_test(h, '0', true)
    do_has_attribute_test(h, '1.b', true)
  end

  protected

  def do_lookup_test (container, expression, expected_value)

    assert_equal(
      expected_value,
      OpenWFE::lookup_attribute(container, expression))
  end

  def do_has_attribute_test (container, expression, expected_boolean)

    assert_equal(
      expected_boolean,
      OpenWFE::has_attribute?(container, expression))
  end
end

