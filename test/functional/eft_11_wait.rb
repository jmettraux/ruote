
#
# Testing Ruote (OpenWFEru)
#
# Thu Jun 18 11:03:45 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftWaitTest < Test::Unit::TestCase
  include FunctionalBase

  def test_wait_for

    pdef = Ruote.process_definition do
      sequence do
        alpha
        wait :for => '1s'
        alpha
      end
    end

    #noisy

    ts = []

    @engine.register_participant :alpha do
      ts << Time.now
    end

    @engine.launch(pdef)

    sleep 1.6

    #p ts
    assert ts[1] - ts[0] > 1.0
  end

  def test_cancel_wait

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        wait :for => '3d'
        echo 'b'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    sleep 0.300

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 'a', @tracer.to_s
    assert_equal 0, @engine.scheduler.jobs.size
  end

  def test_wait_for_number

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        wait 0.500
        echo 'b'
      end
    end

    assert_trace pdef, %w[ a b ]
  end
end

