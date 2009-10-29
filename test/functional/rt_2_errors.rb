
#
# Testing Ruote (OpenWFEru)
#
# Thu Jul 16 13:49:09 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'restart_base')


class RtErrorsTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_err_and_restart

    start_new_engine

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        nada
      end
    end

    wfid = @engine.launch(pdef)

    sleep 0.400

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    @engine.shutdown

    # restart...

    start_new_engine

    sleep 0.400

    assert_equal 1, @engine.processes.size

    ps = @engine.process(wfid)
    assert_equal 1, ps.errors.size

    @engine.cancel_process(wfid)

    sleep 0.400
  end
end

