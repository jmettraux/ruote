
#
# testing ruote
#
# Wed Oct 28 14:51:07 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'restart_base')

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

    @engine.register_participant 'alpha', Ruote::NullParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(3)

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.storage.get_many('schedules').size

    @engine.shutdown

    # restart...

    start_new_engine

    #noisy

    @engine.register_participant 'alpha', Ruote::NullParticipant

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.storage.get_many('schedules').size

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_equal 0, @engine.processes.size
    assert_equal 0, @engine.storage.get_many('schedules').size
  end
end

