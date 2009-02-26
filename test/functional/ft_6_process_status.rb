
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Feb 26 14:59:09 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_process_status

    pdef = OpenWFE.process_definition do
      sequence do
        alpha
      end
    end

    @engine.register_participant(:alpha, OpenWFE::NullParticipant)
      # receives workitems, discards them, doesn't reply to the engine

    fei = @engine.launch(pdef)

    sleep 0.350

    ps = @engine.processes(fei.wfid)
    assert_equal 1, ps.size

    purge_engine
  end

  def test_multiple_process_status

    pdef = OpenWFE.process_definition do
      sequence do
        alpha
      end
    end

    @engine.register_participant(:alpha, OpenWFE::NullParticipant)
      # receives workitems, discards them, doesn't reply to the engine

    fei = @engine.launch(pdef)
    @engine.launch(pdef)

    sleep 0.350

    ps = @engine.processes
    assert_equal 2, ps.size

    ps = @engine.processes(fei.wfid)
    assert_equal 1, ps.size

    purge_engine
  end
end

