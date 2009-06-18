
#
# Testing Ruote (OpenWFEru)
#
# Thu Jun 18 11:03:45 JST 2009
#

require File.dirname(__FILE__) + '/base'


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

    sleep 1.5

    #p ts
    assert ts[1] - ts[0] > 1.0
  end

  def test_cancel_wait

    pdef = Ruote.process_definition do
      concurrence do
        alpha
        sequence do
          wait :for => '3s'
          bravo
        end
      end
    end

    #noisy

    assert true
  end
end

