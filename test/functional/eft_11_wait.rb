
#
# testing ruote
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
        wait :for => '2s'
        alpha
        echo 'done.'
      end
    end

    #noisy

    ts = []
    @engine.register_participant(:alpha) { ts << Time.now }

    assert_trace 'done.', pdef

    #p [ ts[1].sec, ts[0].sec ]
    d = (ts[1].sec - ts[0].sec) % 60

    assert(
      [ 2, 3 ].include?(d),
      "delta is #{d}, which isn't 2 or 3")
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

    wait_for(4)

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 'a', @tracer.to_s
    assert_equal 0, @engine.storage.get_many('schedules').size
  end

  def test_wait_until

    pdef = Ruote.process_definition do
      sequence do
        alpha
        wait :until => (Time.now + 2.0).to_s
        alpha
        echo 'done.'
      end
    end

    #noisy

    ts = []
    @engine.register_participant(:alpha) { ts << Time.now }

    assert_trace 'done.', pdef

    #p ts
    assert ts[1] - ts[0] > 1.0, "#{ts[1] - ts[0]} should be > 1.0"
  end

  def test_wait_until_now

    pdef = Ruote.process_definition do
      sequence do
        echo 'a'
        wait Time.now
        echo 'b'
      end
    end

    #noisy

    assert_trace %w[ a b ], pdef
  end
end

