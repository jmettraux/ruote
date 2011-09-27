
#
# testing ruote
#
# Wed Jul  1 23:22:26 JST 2009
#

require File.expand_path('../base', __FILE__)
require File.expand_path('../restart_base', __FILE__)


class RtWaitTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_wait_and_restart

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo 'in'
        wait '3d'
        echo 'out.'
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(5)

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    @dashboard.shutdown

    # restart...

    start_new_engine

    #noisy

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 0, @dashboard.processes.size
  end
end

