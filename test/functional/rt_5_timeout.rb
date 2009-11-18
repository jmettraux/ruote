
#
# Testing Ruote (OpenWFEru)
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

    wfid = @engine.launch(pdef)

    sleep 0.400

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size

    @engine.shutdown

    # restart...

    start_new_engine

    @engine.register_participant 'alpha', Ruote::NullParticipant

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size

    sleep 0.400

    @engine.cancel_process(wfid)

    sleep 0.400

    assert_equal 0, @engine.processes.size
    assert_equal 0, @engine.scheduler.jobs.size
  end

  # Scheduling info vanished, need to reload it at scheduler#init ...
  #
  def test_damaged_restart

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      #participant 'alpha', :timeout => '2d'
      sequence(:timeout => '2d') { participant 'alpha' }
    end

    @engine.register_participant 'alpha', Ruote::NullParticipant

    wfid = @engine.launch(pdef)

    sleep 0.400

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size

    at = @engine.scheduler.jobs.values.first.at

    @engine.shutdown

    # nuke work/at.ruote

    FileUtils.rm_f(File.join(@engine.workdir, 'at.ruote'))

    # then restart...

    start_new_engine

    @engine.register_participant 'alpha', Ruote::NullParticipant

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size
    assert_in_delta at, @engine.scheduler.jobs.values.first.at, 1.0e-5

    sleep 0.400

    @engine.cancel_process(wfid)

    sleep 0.400

    assert_equal 0, @engine.processes.size
    assert_equal 0, @engine.scheduler.jobs.size
  end
end

