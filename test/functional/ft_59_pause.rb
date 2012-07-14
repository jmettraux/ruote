
#
# testing ruote
#
# Tue Apr 12 06:10:17 JST 2011
#
# Santa Barbara
#

require File.expand_path('../base', __FILE__)


class FtPauseTest < Test::Unit::TestCase
  include FunctionalBase

  def test_pause_process

    @dashboard.register { catchall }

    pdef = Ruote.define { alice }

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alice)

    #
    # pause the process

    @dashboard.pause(wfid)

    @dashboard.wait_for('dispatch_pause')

    ps = @dashboard.ps(wfid)

    assert_equal %w[ paused ], ps.expressions.collect { |fexp| fexp.state }.uniq

    @dashboard.storage_participant.proceed(@dashboard.storage_participant.first)

    @dashboard.wait_for('receive')

    ps = @dashboard.ps(wfid)

    exp = ps.expressions.last

    assert_not_nil exp.h.paused_replies

    #
    # resume the process

    @dashboard.resume(wfid)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.ps(wfid)
  end

  def test_pause_process_in_error

    pdef = Ruote.process_definition do
      nada
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    @dashboard.pause(wfid)

    @dashboard.wait_for(3)

    ps = @dashboard.ps(wfid)

    assert_equal(
      %w[ paused failed ],
      ps.expressions.collect { |fexp| fexp.state })

    #
    # cancel at error

    @dashboard.cancel(ps.expressions.last.fei)

    #
    # resume the process

    @dashboard.resume(wfid)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.ps(wfid)
  end

  def test_cancel_paused_branch

    pdef = Ruote.process_definition do
      sequence do
        alice
      end
      bob
    end

    @dashboard.register do
      catchall
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alice)

    exp = @dashboard.ps(wfid).expressions.find { |e| e.name == 'sequence' }

    @dashboard.pause(exp.fei)

    @dashboard.wait_for('dispatch_pause')

    assert_equal(
      %w[ 0/ 0_0/paused 0_0_0/paused ],
      @dashboard.ps(wfid).expressions.collect { |fe|
        "#{fe.fei.expid}/#{fe.state}"
      })

    @dashboard.cancel(exp.fei)

    @dashboard.wait_for(:bob)

    assert_equal(
      %w[ 0/ 0_1/ ],
      @dashboard.ps(wfid).expressions.collect { |fe|
        "#{fe.fei.expid}/#{fe.state}"
      })
  end

  class AlphaParticipant
    include Ruote::LocalParticipant
    def consume(workitem)
      @context.tracer << "dispatched:#{workitem.fei.wfid}\n"
    end
    def on_pause(fei)
      @context.tracer << "pause:#{fei.wfid}\n"
    end
    def on_resume(fei)
      @context.tracer << "resume:#{fei.wfid}\n"
    end
  end

  def test_propagation_to_participant

    pdef = Ruote.define do
      alpha
    end

    @dashboard.register do
      alpha AlphaParticipant
    end

    wfid = @dashboard.launch(pdef)

    #@dashboard.wait_for(:alpha)
    @dashboard.wait_for('dispatched')

    @dashboard.pause(wfid)

    @dashboard.wait_for('dispatch_pause')

    assert_equal(
      [ "dispatched:#{wfid}", "pause:#{wfid}" ],
      @tracer.to_a)

    @dashboard.resume(wfid)

    @dashboard.wait_for('dispatch_resume')

    assert_equal(
      [ "dispatched:#{wfid}", "pause:#{wfid}", "resume:#{wfid}" ],
      @tracer.to_a)
  end

  def test_propagation_to_participant_when_participant_has_already_replied

    pdef = Ruote.define do
      alpha
    end

    @dashboard.register do
      alpha AlphaParticipant
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    @dashboard.pause(wfid)

    @dashboard.wait_for('dispatch_pause')

    wi = @dashboard.ps(wfid).expressions.last.h.applied_workitem

    part = @dashboard.participant(:alpha.to_s)

    part.instance_eval { reply_to_engine(Ruote::Workitem.new(wi)) }

    @dashboard.wait_for(1)

    assert_equal(
      [ "dispatched:#{wfid}", "pause:#{wfid}" ],
      @tracer.to_a)

    @dashboard.resume(wfid)

    @dashboard.wait_for(wfid)

    assert_equal(
      [ "dispatched:#{wfid}", "pause:#{wfid}" ],
      @tracer.to_a)
        #
        # no 'resume:xxx'
  end

  def test_breakpoint

    pdef = Ruote.define do
      sequence do
        alpha
      end
    end

    @dashboard.register do
      catchall
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    sequence = @dashboard.ps(wfid).expressions[1]

    @dashboard.pause(sequence.fei, :breakpoint => true)

    @dashboard.storage_participant.proceed(@dashboard.storage_participant.first)

    @dashboard.wait_for('reply')

    assert_equal(
      [ nil, 'paused' ],
      @dashboard.ps(wfid).expressions.collect { |fexp| fexp.state })
  end

  def test_no_propagation_to_participant_when_breakpoint

    pdef = Ruote.define do
      alpha
    end

    @dashboard.register do
      alpha AlphaParticipant
    end

    wfid = @dashboard.launch(pdef)

    #@dashboard.wait_for(:alpha)
    @dashboard.wait_for('dispatched')

    alpha = @dashboard.ps(wfid).expressions.last

    @dashboard.pause(alpha.fei, :breakpoint => true)

    @dashboard.wait_for('pause')

    assert_equal([ "dispatched:#{wfid}" ], @tracer.to_a)

    @dashboard.resume(alpha.fei)

    @dashboard.wait_for('resume')

    assert_equal([ "dispatched:#{wfid}" ], @tracer.to_a)
  end

  def test_resume_anyway

    pdef = Ruote.define do
      concurrence do
        alpha
        sequence do
          bravo
        end
      end
    end

    @dashboard.register do
      catchall
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(:bravo)

    exps = @dashboard.ps(wfid).expressions.select { |fexp|
      fexp.fei.expid.match(/^0_0_[01]$/)
    }

    exps.each { |fexp| @dashboard.pause(fexp.fei) }

    @dashboard.wait_for('dispatch_pause')
    @dashboard.wait_for('dispatch_pause')

    assert_equal(
      [ nil, nil, 'paused', 'paused', 'paused' ],
      @dashboard.ps(wfid).expressions.collect { |fexp| fexp.state })

    @dashboard.resume(wfid)
      # won't resume the process, since the root is not paused

    @dashboard.wait_for(2)

    assert_equal(
      [ nil, nil, 'paused', 'paused', 'paused' ],
      @dashboard.ps(wfid).expressions.collect { |fexp| fexp.state })

    @dashboard.resume(wfid, :anyway => true)

    @dashboard.wait_for('dispatch_resume')
    @dashboard.wait_for('dispatch_resume')

    assert_equal(
      [ nil, nil, nil, nil, nil ],
      @dashboard.ps(wfid).expressions.collect { |fexp| fexp.state })
  end
end

