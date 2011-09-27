
#
# testing ruote
#
# Thu Jul  2 12:51:54 JST 2009
#

require File.expand_path('../base', __FILE__)
require File.expand_path('../restart_base', __FILE__)


require 'ruote/participant'


class RtListenTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_listen_and_restart

    start_new_engine

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          listen :to => '/^al.*/', :upon => 'reply'
          echo 'done.'
        end
        alpha
      end
    end

    #puts; noisy

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal '', @tracer.to_s

    @dashboard.shutdown

    start_new_engine

    #puts; noisy

    @dashboard.reply(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end
end

