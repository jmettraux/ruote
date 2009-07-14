
#
# Testing Ruote
#
# Fri May 15 10:08:51 JST 2009
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'ruote/fei'


class FeiTest < Test::Unit::TestCase

  def test_from_h

    fei = Ruote::FlowExpressionId.from_h(
      :engine_id => 'ei', :wfid => 'wfid', :expid => '0')

    assert_equal 'ei|wfid|0', fei.to_s
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
end

