
#
# testing ruote
#
# Mon Jun 15 16:43:06 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/fei'
require 'ruote/workitem'


class UtWorkitemTest < Test::Unit::TestCase

  def test_equality

    f0 = { 'expid' => '0', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }
    f1 = { 'expid' => '0', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }
    f2 = { 'expid' => '1', 'wfid' => '20101224-baba', 'engine_id' => 'engine' }

    w0 = Ruote::Workitem.new('fei' => f0, 'fields' => { 'a' => 'A' })
    w1 = Ruote::Workitem.new('fei' => f1, 'fields' => { 'b' => 'B' })
    w2 = Ruote::Workitem.new('fei' => f2, 'fields' => { 'c' => 'C' })

    assert w0 == w1
    assert w0 != w2

    assert_equal w0.hash, w1.hash
    assert_not_equal w0.hash, w2.hash
  end
end

