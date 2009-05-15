
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
end

