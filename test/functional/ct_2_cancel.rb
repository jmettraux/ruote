
#
# testing ruote
#
# Mon Dec 28 19:13:02 JST 2009
#

require File.expand_path('../concurrent_base', __FILE__)


class CtCancelTest < Test::Unit::TestCase
  include ConcurrentBase

  # A collision between a reply and a cancel
  #
  # The first one to occur should neutralize the other (and the flow should
  # not stall).
  #
  def test_collision

    pdef = Ruote.process_definition do
      sequence do
        alpha
      end
    end

    alpha = @dashboard0.register_participant :alpha do |workitem|
      # let reply immediately
    end

    wfid = @dashboard0.launch(pdef)

    #
    # test preparation...

    @dashboard0.step 6

    dispatched_seen = false
    reply_msg = nil

    #
    # reach the point where the reply is coming (and the dispatched msg has
    # passed)

    loop do
      m = @dashboard0.next_msg
      ma = m['action']
      if ma == 'dispatched'
        dispatched_seen = true
        @dashboard0.do_process(m)
        break if reply_msg
      elsif ma == 'reply'
        reply_msg = m
        break if dispatched_seen
      else
        @dashboard0.do_process(m)
      end
    end

    #
    # inject the cancel message

    @dashboard0.cancel_expression(
      { 'engine_id' => 'engine', 'wfid' => wfid, 'expid' => '0_0' })

    msgs = @dashboard0.gather_msgs

    msgs = msgs - [ reply_msg ]

    assert_equal 1, msgs.size
    assert_equal 'cancel', msgs.first['action']
      #
      # trusting is good, checking is better

    #
    # try to force a collision between the reply msg and the cancel msg

    t1 = Thread.new { @dashboard1.do_process(msgs.first) }
    t0 = Thread.new { @dashboard0.do_process(reply_msg) }
    t1.join
    t0.join

    loop do
      m = @dashboard0.next_msg
      @dashboard0.do_process(m)
      break if m['action'] == 'terminated'
    end

    assert_nil @dashboard0.process(wfid)
  end
end

