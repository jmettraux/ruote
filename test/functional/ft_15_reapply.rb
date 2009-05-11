
#
# Testing Ruote (OpenWFEru)
#
# jmettraux@gmail.com
#
# Mon May 11 13:38:24 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtReapplyTest < Test::Unit::TestCase
  include FunctionalBase

  class UnreliableParticipant
    include OpenWFE::LocalParticipant

    def consume (workitem)
      @counter ||= 0
      @counter += 1
      reply_to_engine(workitem) if @counter == 2
    end
  end

  def test_sequence_reapply

    @engine.register_participant :alpha, UnreliableParticipant

    fei = @engine.launch(OpenWFE.process_definition(:name => 'x') do
      sequence do
        alpha
        echo 'hello (${f:__reapplied__})'
      end
    end)

    sleep 0.350

    assert_equal '', @tracer.to_s

    alpha = @engine.process_status(fei.wfid).expressions.last.fei

    @engine.reapply(alpha)

    sleep 0.350

    assert_equal 'hello (true)', @tracer.to_s

    #purge_engine
  end
end

