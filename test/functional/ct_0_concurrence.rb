
#
# testing ruote
#
# Wed Jul  8 15:30:55 JST 2009
#

require File.join(File.dirname(__FILE__), 'concurrent_base')

#require 'ruote/part/hash_participant'


class CtConcurrenceTest < Test::Unit::TestCase
  include ConcurrentBase

  def test_collision

    pdef = Ruote.process_definition do
      concurrence do
        echo 'a'
        echo 'b'
      end
    end

    #noisy

    wfid = @engine0.launch(pdef)

    replies = []

    while replies.size < 2

      msg = @engine0.next_msg

      if msg['action'] == 'reply'
        replies << msg
      else
        @engine0.do_process(msg)
      end
    end

    replies.sort! { |a, b| a['put_at'] <=> b['put_at'] }

    t0 = Thread.new { @engine1.do_process(replies[0]) }
    t1 = Thread.new { @engine0.do_process(replies[1]) }
    t0.join
    t1.join

    msgs = @engine0.gather_msgs

    assert_equal 1, msgs.size, 'exactly 1 message was expected'

    msg = msgs.first

    assert_equal 'reply', msg['action']
    assert_equal '0', msg['fei']['expid']
  end
end

