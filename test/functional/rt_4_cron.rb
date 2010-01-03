
#
# testing ruote
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

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(3)

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.storage.get_many('schedules').size

    @engine.shutdown

    # restart...

    start_new_engine

    #noisy

    @engine.variables['text'] = 'post'

    assert_equal 1, @engine.processes.size
    assert_equal 1, @engine.storage.get_many('schedules').size

    wait_for(4)

    assert_match /pre\npost/, @tracer.to_s

    @engine.cancel_process(wfid)

    while msg = wait_for(wfid)
      break if msg['action'] == 'terminated'
    end

    assert_equal 0, @engine.processes.size
    assert_equal 0, @engine.storage.get_many('schedules').size
  end
end

