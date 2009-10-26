
#
# Testing Ruote (OpenWFEru)
#
# Tue Oct 27 01:36:52 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'restart_base')


class RtWhenTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_when_and_restart

    #FileUtils.rm_f('work')

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo 'in'
        _when '${v:resume}', :freq => '500'
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

    @engine.variables['resume'] = true

    wait_for(wfid)

    assert_equal "in\nout.", @tracer.to_s

    assert_equal 0, @engine.processes.size
    assert_equal 0, @engine.scheduler.jobs.size
  end
end

