
#
# testing ruote
#
# Thu Jul 16 13:49:09 JST 2009
#

require File.expand_path('../base', __FILE__)
require File.expand_path('../restart_base', __FILE__)


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

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.errors.size

    @dashboard.shutdown

    # restart...

    start_new_engine

    #@dashboard.noisy = true

    assert_equal 1, @dashboard.processes.size

    ps = @dashboard.process(wfid)
    assert_equal 1, ps.errors.size

    @dashboard.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
  end
end

