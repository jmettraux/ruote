
#
# Testing Ruote (OpenWFEru)
#
# Wed Jul  1 23:22:26 JST 2009
#

require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/restart_base'


class RtWaitTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_wait_and_restart

    #FileUtils.rm_f('work')

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo 'in'
        wait '3d'
        echo 'out.'
      end
    end

    wfid = @engine.launch(pdef)

    sleep 0.200

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size

    @engine.shutdown

    # restart...

    start_new_engine

    sleep 0.200

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size

    @engine.cancel_process(wfid)

    sleep 0.200

    assert_equal 0, @engine.processes.size
  end
end

