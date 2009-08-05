
#
# Testing Ruote
#
# Mon Jun 15 16:43:06 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/fei'
require 'ruote/workitem'


class WorkitemTest < Test::Unit::TestCase

  def test_to_h

    wi = Ruote::Workitem.new

    wi.fei = Ruote::FlowExpressionId.from_h(
      'engine_id' => 'toto', 'wfid' => '12345-4566', 'expid' => '0_1_0')

    assert_equal(
      {"fei"=>{"class"=>"Ruote::FlowExpressionId", "engine_id"=>"toto", "wfid"=>"12345-4566", "expid"=>"0_1_0"}, "participant_name"=>nil, "fields"=>{}},
      wi.to_h)
  end

  def test_from_h

    wi = Ruote::Workitem.from_h({"fei"=>{"class"=>"Ruote::FlowExpressionId", "engine_id"=>"toto", "wfid"=>"12345-4566", "expid"=>"0_1_0"}, "participant_name"=>nil, "fields"=>{}})

    assert_equal 0, wi.fields.size
    assert_equal '0_1_0', wi.fei.expid
  end
end

