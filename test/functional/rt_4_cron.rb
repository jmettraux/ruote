
#
# testing ruote
#
# Wed Oct 28 12:51:04 JST 2009
#

require File.expand_path('../base', __FILE__)
require File.expand_path('../restart_base', __FILE__)


class RtCronTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_cron_restart

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      cron '* * * * * *' do # every second
        echo '${v:text}'
      end
    end

    @dashboard.variables['text'] = 'pre'

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    wait_for(5)

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    @dashboard.shutdown

    # restart...

    start_new_engine

    #@dashboard.noisy = true

    @dashboard.variables['text'] = 'post'

    assert_equal 1, @dashboard.processes.size
    assert_equal 1, @dashboard.storage.get_many('schedules').size

    wait_for(5)

    assert_match /pre\npost/, @tracer.to_s

    @dashboard.cancel_process(wfid)

    while msg = wait_for(wfid)
      break if msg['action'] == 'terminated'
    end

    assert_equal 0, @dashboard.processes.size
    assert_equal 0, @dashboard.storage.get_many('schedules').size
  end
end

