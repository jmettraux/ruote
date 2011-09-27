
#
# testing ruote
#
# Wed Jul  8 15:30:55 JST 2009
#

require File.expand_path('../concurrent_base', __FILE__)


class CtConcurrenceTest < Test::Unit::TestCase
  include ConcurrentBase

  # A collision between two workers replying to the same concurrence expression.
  #
  # Worker 0 replies for echo 'a' while worker 1 replies for echo 'b'.
  #
  def test_collision

    pdef = Ruote.process_definition do
      concurrence do
        echo 'a'
        echo 'b'
      end
    end

    wfid = @dashboard0.launch(pdef)

    replies = []

    while replies.size < 2

      msg = @dashboard0.next_msg

      if msg['action'] == 'reply'
        replies << msg
      else
        @dashboard0.do_process(msg)
      end
    end

    replies.sort! { |a, b| a['put_at'] <=> b['put_at'] }

    #replies.each { |r| p r }

    t0 = Thread.new { @dashboard1.do_process(replies[0]) }
    t1 = Thread.new { @dashboard0.do_process(replies[1]) }
    t0.join
    t1.join

    msgs = @dashboard0.gather_msgs

    assert_equal 1, msgs.size, 'exactly 1 message was expected'

    msg = msgs.first

    assert_equal 'reply', msg['action']
    assert_equal '0', msg['fei']['expid']
  end
end

