
#
# testing ruote
#
# Thu Jul  2 12:51:54 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')
require File.join(File.dirname(__FILE__), 'restart_base')


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

    #puts; noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal '', @tracer.to_s

    @engine.shutdown

    start_new_engine

    #puts; noisy

    @engine.reply(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end
end

