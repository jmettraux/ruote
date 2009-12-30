
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
    end

    #msgs.each { |m| p m }

    t1 = Thread.new { @engine0.do_step(msgs[1]) }
    t0 = Thread.new { @engine1.do_step(msgs[0]) }
    t1.join
    t0.join

    #p @storage.get_msgs

    exps = @storage.get_many('expressions')

    #exps.each do |exp|
    #  p [ exp['fei']['expid'], exp['original_tree'] ]
    #end

    assert_equal 1, exps.size

    #@engine0.step 1
  end
end

