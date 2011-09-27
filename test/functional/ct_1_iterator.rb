
#
# testing ruote
#
# Mon Dec  7 13:54:18 JST 2009
#

require File.expand_path('../concurrent_base', __FILE__)


class CtIteratorTest < Test::Unit::TestCase
  include ConcurrentBase

  # Test proper handling of collisions between an iterator and another worker
  # passing a stop command.
  #
  def test_collision

    pdef = Ruote.process_definition do
      concurrence do
        iterator :on => (1..10).to_a, :tag => 'it' do
          echo '${v:i}'
        end
        sequence do
          sequence do
            stop :ref => 'it'
          end
        end
      end
    end

    wfid = @dashboard0.launch(pdef)

    stop_msg = nil

    loop do
      m = @dashboard0.next_msg
      if m['command']
        stop_msg = m
        break
      end
      @dashboard0.do_process(m)
    end

    assert_equal 'stop', stop_msg['command'].first
    assert_equal '0_0_0', stop_msg['fei']['expid']

    msg = @dashboard0.next_msg

    t0 = Thread.new { @dashboard1.do_process(stop_msg) }
    t1 = Thread.new { @dashboard0.do_process(msg) }
    t0.join
    t1.join

    loop do
      m = @dashboard0.next_msg
      break if m['action'] == 'terminated'
      @dashboard0.do_process(m)
    end

    assert_equal "1\n2", @tracer0.to_s
    assert_equal '', @tracer1.to_s
  end
end

