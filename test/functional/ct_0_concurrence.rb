
#
# Testing Ruote (OpenWFEru)
#
# Wed Jul  8 15:30:55 JST 2009
#

require File.join(File.dirname(__FILE__), 'concurrent_base')

#require 'ruote/part/hash_participant'


class CtConcurrenceTest < Test::Unit::TestCase
  include ConcurrentBase

  def test_only_one_engine

    pdef = Ruote.process_definition do
      concurrence do
        echo 'a'
        echo 'b'
      end
    end

    @engine0.launch(pdef)

    assert_equal 1, @storage.get_msgs.size

    @engine0.process_next_msg 7

    assert_equal 'terminated', @storage.get_msgs.first['action']

    @engine0.process_next_msg

    assert_equal 0, @storage.get_msgs.size

    assert_equal "a\nb", @tracer0.to_s
  end

  def test_two_engines

    pdef = Ruote.process_definition do
      concurrence do
        echo 'a'
        echo 'b'
      end
    end

    noisy

    @engine0.launch(pdef)

    @engine1.process_next_msg

    assert_equal 1, @storage.get_msgs.size

    @engine0.process_next_msg

    assert_equal 2, @storage.get_msgs.size

    @engine1.process_next_msg
    @engine0.process_next_msg

    assert_equal 2, @storage.get_msgs.size

    @engine1.process_next_msg
    @engine0.process_next_msg

    assert_equal 1, @storage.get_msgs.size

    @engine1.process_next_msg 2

    assert_equal 0, @storage.get_msgs.size
  end
end

