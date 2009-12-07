
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
    @engine0.step 11

    msgs = @storage.get_msgs
    msg0 = msgs[0]
    msg1 = msgs[1]

    p msg0, msg1

    assert_equal 'stop', msg0['command'].first
    assert_equal '0_0_0', msg0['fei']['expid']
    assert_equal '0_0_1_0', msg1['fei']['expid']

    t0 = Thread.new { @engine1.do_step(msg0) }
    t1 = Thread.new { @engine0.do_step(msg1) }
    t0.join
    t1.join

    #@engine0.step 4
    @engine1.walk

    assert_equal "1\n2", @tracer0.to_s
    assert_equal "", @tracer1.to_s
  end
end

