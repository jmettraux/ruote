
#
# testing ruote
#
# Fri May 15 10:08:51 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote'


class UtFeiTest < Test::Unit::TestCase

  def test_misc

    fei = Ruote::FlowExpressionId.new(
      'expid' => '0_0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine')

    assert_equal(
      '0_0!!20101224-bababa',
      fei.to_storage_id)

    assert_equal(
      0,
      fei.child_id)

    assert_equal(
      {"wfid"=>"20101224-bababa", "engine_id"=>"engine", "expid"=>"0_0"},
      fei.to_h)
  end

  def test_direct_child

    f0 = {
      'expid' => '0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine' }
    f1 = {
      'expid' => '0_0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine' }
    f2 = {
      'expid' => '0_0_0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine' }
    f3 = {
      'expid' => '0_0', 'wfid' => '20101224-bakayaro', 'engine_id' => 'engine' }

    assert_equal false, Ruote::FlowExpressionId.direct_child?(f0, f0)
    assert_equal true, Ruote::FlowExpressionId.direct_child?(f0, f1)
    assert_equal false, Ruote::FlowExpressionId.direct_child?(f0, f2)
    assert_equal false, Ruote::FlowExpressionId.direct_child?(f0, f3)
  end

  def test_is_a_fei

    assert_equal(
      true,
      Ruote::FlowExpressionId.is_a_fei?(
        'expid' => '0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine'))
    assert_equal(
      false,
      Ruote::FlowExpressionId.is_a_fei?(
        'nada' => '0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine'))
  end

  def test_equality

    f0 = Ruote::FlowExpressionId.new(
      'expid' => '0_0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine')
    f1 = Ruote::FlowExpressionId.new(
      'expid' => '0_0', 'wfid' => '20101224-bababa', 'engine_id' => 'engine')
    f2 = Ruote::FlowExpressionId.new(
      'expid' => '0_1', 'wfid' => '20101224-bababa', 'engine_id' => 'engine')

    assert f0 == f1
    assert f0 != f2

    assert_equal f0.hash, f1.hash
    assert_not_equal f0.hash, f2.hash
  end

  def test_from_id

    assert_equal(
      '0_0_1!!20100224-fake',
      Ruote::FlowExpressionId.from_id('0_0_1!!20100224-fake').to_storage_id)
    assert_equal(
      '0_0_1!!20100224-fake',
      Ruote::FlowExpressionId.from_id('wi!0_0_1!!20100224-fake').to_storage_id)
    assert_equal(
      '0_0_1!!20100224-fake',
      Ruote::FlowExpressionId.from_id('wi!store!0_0_1!!20100224-fake').to_storage_id)

    assert_equal(
      '0_0_1!!20100224-fake',
      Ruote::FlowExpressionId.from_id('eng!0_0_1!!20100224-fake').to_storage_id)
    assert_equal(
      'eng',
      Ruote::FlowExpressionId.from_id('eng!0_0_1!!20100224-fake').engine_id)
  end

  def test_extract_h

    assert_equal(
      { 'engine_id' => 'engine',
        'expid' => '0_0_1',
        'sub_wfid' => '',
        'wfid' => '20100224-fake' },
      Ruote::FlowExpressionId.extract_h('0_0_1!!20100224-fake'))
  end

  def test_extract
    assert_equal(
      Ruote::FlowExpressionId.new(
        { 'engine_id' => 'engine',
          'expid' => '0_0_1',
          'sub_wfid' => '',
          'wfid' => '20100224-fake' }),
      Ruote::FlowExpressionId.extract('0_0_1!!20100224-fake'))
  end
end

