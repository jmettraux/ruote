
#
# Testing Ruote (OpenWFEru)
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

    noisy

    wfid = @engine0.launch(pdef)

    #@engine0.step 11
    msg = @engine0.step_until { |msg| msg['command'] != nil }

    assert_equal 'stop', msg['command'].first
    assert_equal '0_0_0', msg['fei']['expid']

    msgs = @storage.get_msgs

    assert_equal 3, msgs.size

    msgs = msgs - [ msg ]

    assert_equal 2, msgs.size

    msg1 = msgs.first

    t0 = Thread.new { @engine1.do_step(msg) }
    t1 = Thread.new { @engine0.do_step(msg1) }
    t0.join
    t1.join

    #@engine0.step 4
    @engine1.walk

    assert_equal "1\n2", @tracer0.to_s
    assert_equal "", @tracer1.to_s
  end
end

