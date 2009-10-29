
#
# Testing Ruote (OpenWFEru)
#
# Wed Oct 28 12:51:04 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'restart_base')


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

    @engine.variables['text'] = 'pre'

    wfid = @engine.launch(pdef)

    sleep 1.2

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size

    @engine.shutdown

    # restart...

    start_new_engine

    @engine.variables['text'] = 'post'

    sleep 1.2

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.scheduler.jobs.size

    sleep 0.400

    assert_match /pre\npost/, @tracer.to_s

    @engine.cancel_process(wfid)

    sleep 0.400

    assert_equal 0, @engine.processes.size
    assert_equal 0, @engine.scheduler.jobs.size
  end
end

