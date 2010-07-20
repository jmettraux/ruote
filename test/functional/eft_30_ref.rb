
#
# testing ruote
#
# Tue Jul 20 12:47:36 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class EftRefTest < Test::Unit::TestCase
  include FunctionalBase

  class AlphaParticipant
    include Ruote::LocalParticipant

    def consume (workitem)
      @context.tracer << workitem.fei.expid
      @context.tracer << "\n"
      reply(workitem)
    end
  end

  def test_participant

    pdef = Ruote.process_definition do
      ref :ref => 'alpha'
      ref 'alpha'
      echo 'done.'
    end

    @engine.register_participant :alpha, AlphaParticipant

    #noisy

    assert_trace %w[ 0_0 0_1 done. ], pdef
  end

  def test_subprocess

    pdef = Ruote.process_definition do

      define 'alpha' do
        echo 'alpha'
      end

      sequence do
        ref :ref => 'alpha'
        ref 'alpha'
        echo 'done.'
      end
    end

    assert_trace %w[ alpha alpha done. ], pdef
  end

  def test_missing_participant_ref

    pdef = Ruote.process_definition do
      ref 'alpha'
    end

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    # correct problem and replay at error

    @engine.register_participant 'alpha', AlphaParticipant

    @engine.replay_at_error(ps.errors.first)

    @engine.wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal '0_0', @tracer.to_s
  end

  def test_missing_subprocess_ref

    pdef = Ruote.process_definition do
      ref 'alpha'
    end

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    ps = @engine.process(wfid)

    assert_equal 1, ps.errors.size

    # correct problem and replay at error

    @engine.variables['alpha'] = Ruote.process_definition do
      echo 'alpha'
    end

    @engine.replay_at_error(ps.errors.first)

    @engine.wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal 'alpha', @tracer.to_s
  end
end

