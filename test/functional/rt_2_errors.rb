
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

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(3)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    @engine.shutdown

    # restart...

    start_new_engine

    #noisy

    assert_equal 1, @engine.processes.size

    ps = @engine.process(wfid)
    assert_equal 1, ps.errors.size

    @engine.cancel_process(wfid)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end
end

