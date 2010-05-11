
#
# testing ruote
#
# Mon Dec 28 19:13:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'concurrent_base')


class CtCancelTest < Test::Unit::TestCase
  include ConcurrentBase

  def test_collision

    pdef = Ruote.process_definition do
      sequence do
        alpha
      end
    end

    alpha = @engine0.register_participant :alpha do |workitem|
      # let reply immediately
    end

    #noisy

    wfid = @engine0.launch(pdef)

    @engine0.step 7

    dispatched_seen = false
    reply_msg = nil

    loop do
      m = @engine0.next_msg
      ma = m['action']
      if ma == 'dispatched'
        dispatched_seen = true
        @engine0.do_process(m)
        break if reply_msg
      elsif ma == 'reply'
        reply_msg = m
        break
      else
        @engine0.do_process(m)
      end
    end

    #p dispatched_seen

    @engine0.cancel_expression(
      { 'engine_id' => 'engine', 'wfid' => wfid, 'expid' => '0_0' })

    msgs = @engine0.gather_msgs

    msgs = msgs - [ reply_msg ]

    assert_equal 1, msgs.size
    assert_equal 'cancel', msgs.first['action']

    t1 = Thread.new { @engine1.do_process(msgs.first) }
    t0 = Thread.new { @engine0.do_process(reply_msg) }
    t1.join
    t0.join

    loop do
      m = @engine0.next_msg
      @engine0.do_process(m)
      break if m['action'] == 'terminated'
    end

    assert_nil @engine0.process(wfid)
  end
end

