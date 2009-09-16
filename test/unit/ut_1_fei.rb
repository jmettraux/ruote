
#
# Testing Ruote
#
# Fri May 15 10:08:51 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/fei'


class FeiTest < Test::Unit::TestCase

  def test_from_h

    fei = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid', :expid => '0')

    assert_equal 'ei|wfid|0', fei.to_s
  end

  def test_from_s

    fei = Ruote::FlowExpressionId.from_s('ei|wfid|0')

    assert_equal 'ei', fei.engine_id
    assert_equal 'wfid', fei.wfid
    assert_equal '0', fei.expid
  end

  def test_sub_wfid

    fei = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid', :expid => '0')

    assert_equal 'wfid', fei.wfid
    assert_equal 'wfid', fei.parent_wfid
    assert_equal nil, fei.sub_wfid
  end

  def test_parent_wfid

    fei = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'w_f_i_d_0', :expid => '0')

    assert_equal 'w_f_i_d', fei.parent_wfid
  end

  def test_static_wfid_split

    assert_equal 'ab__cc', Ruote::FlowExpressionId.parent_wfid('ab__cc_9')
    assert_equal '9', Ruote::FlowExpressionId.sub_wfid('ab__cc_9')
  end

  def test_diff

    fei0 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid', :expid => '0')
    fei1 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid', :expid => '0_1')
    fei2 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid_0', :expid => '0')
    fei3 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid_0', :expid => '1')
    fei4 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei-other', :wfid => 'wfid', :expid => '0')
    fei5 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid_1', :expid => '0')

    assert_equal 1, fei0.diff(fei1)
    assert_equal '0', fei0.diff(fei2)
    assert_equal fei3, fei0.diff(fei3)
    assert_equal fei4, fei0.diff(fei4)

    assert_equal '1', fei3.diff(fei5)
  end

  def test_undiff

    fei0 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid', :expid => '0')
    fei1 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid', :expid => '0_1')
    fei2 = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid_0', :expid => '0')

    assert_equal fei1, fei0.undiff(1)
    assert_equal fei2, fei0.undiff('0')
    assert_equal fei1, fei0.undiff(fei1)
  end
end

