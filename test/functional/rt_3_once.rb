
#
# testing ruote
#
# Tue Oct 27 01:36:52 JST 2009
#

require File.expand_path('../base', __FILE__)
require File.expand_path('../restart_base', __FILE__)


class RtWhenTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_once_and_restart

    do_test('1s')
  end

  def test_once_cron_and_restart

    do_test('* * * * * *')
  end

  protected

  def do_test(freq)

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo 'in'
        once '${v:resume}', :freq => freq
        echo 'out.'
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    wait_for(5)

    sleep 0.300
      # give it some time to register the schedule

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    @dashboard.shutdown

    # restart...

    start_new_engine

    sleep 0.500

    #noisy

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    @dashboard.variables['resume'] = true

    wait_for(wfid)

    assert_equal "in\nout.", @tracer.to_s

    assert_equal 0, @dashboard.processes.size
    assert_equal 0, @dashboard.storage.get_many('schedules').size
  end
end

