
#
# testing ruote
#
# Wed Oct 28 14:51:07 JST 2009
#

require File.expand_path('../base', __FILE__)
require File.expand_path('../restart_base', __FILE__)

require 'ruote/part/null_participant'


class RtTimeoutTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  # Vanilla case, no need to reload.
  #
  def test_restart

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      participant 'alpha', :timeout => '2d'
    end

    @dashboard.register_participant 'alpha', Ruote::NullParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    wait_for(3)

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    @dashboard.shutdown

    # restart...

    start_new_engine

    #noisy

    @dashboard.register_participant 'alpha', Ruote::NullParticipant

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 0, @dashboard.processes.size
    assert_equal 0, @dashboard.storage.get_many('schedules').size
  end
end

