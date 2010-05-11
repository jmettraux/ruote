
#
# testing ruote
#
# Mon Dec  7 13:54:18 JST 2009
#

require File.join(File.dirname(__FILE__), 'concurrent_base')


class CtIteratorTest < Test::Unit::TestCase
  include ConcurrentBase

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

    #noisy

    wfid = @engine0.launch(pdef)

    stop_msg = nil

    loop do
      m = @engine0.next_msg
      if m['command']
        stop_msg = m
        break
      end
      @engine0.do_process(m)
    end

    assert_equal 'stop', stop_msg['command'].first
    assert_equal '0_0_0', stop_msg['fei']['expid']

    msg = @engine0.next_msg

    t0 = Thread.new { @engine1.do_process(stop_msg) }
    t1 = Thread.new { @engine0.do_process(msg) }
    t0.join
    t1.join

    loop do
      m = @engine0.next_msg
      break if m['action'] == 'terminated'
      @engine0.do_process(m)
    end

    assert_equal "1\n2", @tracer0.to_s
    assert_equal '', @tracer1.to_s
  end
end

