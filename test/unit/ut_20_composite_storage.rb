
#
# testing ruote
#
# Sun Mar 14 21:25:52 JST 2010
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote'
require 'ruote/storage/composite_storage'


class UtCompositeStorageTest < Test::Unit::TestCase

  def setup

    @msgs = Ruote::HashStorage.new({})
    @default = Ruote::HashStorage.new({})
    @cs = Ruote::CompositeStorage.new(@default, 'msgs' => @msgs)
  end

  def test_initial

    @cs.put('action' => 'terminate', 'type' => 'msgs', '_id' => 'xxx')
    @cs.put_msg('terminate', 'type' => 'msgs')
    @cs.put_schedule('at', {}, Time.now + 10, 'action' => 'reply')

    assert_equal 0, @default.h['msgs'].size
    assert_equal 1, @default.h['schedules'].size
    assert_equal 2, @cs.get_msgs.size
    assert_equal 2, @msgs.get_msgs.size
    assert_equal 0, @msgs.h['schedules'].size
  end

  def test_delete

    @cs.put('action' => 'terminate', 'type' => 'msgs', '_id' => 'xxx')

    msg = @cs.get_many('msgs').first

    r = @cs.delete(msg)

    assert_nil r
    assert_equal 0, @default.h['msgs'].size
  end
end

