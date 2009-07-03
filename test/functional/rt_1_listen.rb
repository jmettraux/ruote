
#
# Testing Ruote (OpenWFEru)
#
# Thu Jul  2 12:51:54 JST 2009
#

require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/restart_base'


require 'ruote/part/hash_participant'


class RtListenTest < Test::Unit::TestCase
  include FunctionalBase
  include RestartBase

  def test_listen_and_restart

    start_new_engine

    pdef = Ruote.process_definition do
      concurrence do
        sequence do
          listen :to => '^al.*', :upon => 'reply'
          echo 'done.'
        end
        alpha
      end
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal '', @tracer.to_s

    @engine.shutdown

    start_new_engine

    #noisy

    sleep 0.050

    #@engine.tracker.send(:reload)
    #assert_equal 1, @engine.tracker.send(:listeners).size

    @engine.reply(alpha.first)

    sleep 0.050

    assert_equal 'done.', @tracer.to_s
  end
end

