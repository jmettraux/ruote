
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

    @engine0.step 6

    @engine1.cancel_expression(
      { 'engine_id' => 'engine', 'wfid' => wfid, 'expid' => '0_0' })

    msgs = nil
    loop do
      msgs = @storage.get_msgs
      break if msgs.size == 2
      #p msgs.collect { |m| m['fei']['expid'] }.uniq
      #break if
      #  msgs.size == 2 &&
      #  msgs.collect { |m| m['fei']['expid'] }.uniq == %w[ 0_0 ]
    end

    #msgs.each { |m| p m }
    #puts

    t1 = Thread.new { @engine1.do_step(msgs[1]) }
    t0 = Thread.new { @engine0.do_step(msgs[0]) }
    t1.join
    t0.join

    #puts

    @engine0.step 4

    sleep 0.010

    assert_equal 0, @storage.get_msgs.size

    exps = @storage.get_many('expressions')
    exps.each { |exp|
      p [ exp['fei']['expid'], exp['original_tree'] ]
    } if exps.size > 0

    assert_equal 0, exps.size
  end
end

