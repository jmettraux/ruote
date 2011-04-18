
#
# testing ruote
#
# Tue Apr 12 06:10:17 JST 2011
#
# Santa Barbara
#

require File.join(File.dirname(__FILE__), 'base')


class FtPauseTest < Test::Unit::TestCase
  include FunctionalBase

  def test_pause_process

    pdef = Ruote.process_definition do
      alice
    end

    @engine.register do
      catchall
    end

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alice)

    #
    # pause the process

    @engine.pause(wfid)

    sleep 0.500

    ps = @engine.ps(wfid)

    assert_equal %w[ paused ], ps.expressions.collect { |fexp| fexp.state }.uniq

    @engine.storage_participant.proceed(@engine.storage_participant.first)

    sleep 0.500

    ps = @engine.ps(wfid)

    exp = ps.expressions.last

    assert_not_nil exp.h.paused_replies

    #
    # resume the process

    @engine.resume(wfid)

    @engine.wait_for(wfid)

    assert_nil @engine.ps(wfid)
  end

  def test_pause_process_in_error

    pdef = Ruote.process_definition do
      nada
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    @engine.pause(wfid)

    sleep 0.500

    ps = @engine.ps(wfid)

    assert_equal(
      %w[ paused failed ],
      ps.expressions.collect { |fexp| fexp.state })

    #
    # cancel at error

    @engine.cancel(ps.expressions.last.fei)

    #
    # resume the process

    @engine.resume(wfid)

    @engine.wait_for(wfid)

    assert_nil @engine.ps(wfid)
  end

  def test_cancel_paused_branch

    pdef = Ruote.process_definition do
      sequence do
        alice
      end
      bob
    end

    @engine.register do
      catchall
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alice)

    exp = @engine.ps(wfid).expressions.find { |e| e.name == 'sequence' }

    @engine.pause(exp.fei)

    sleep 0.500

    assert_equal(
      %w[ 0/ 0_0/paused 0_0_0/paused ],
      @engine.ps(wfid).expressions.collect { |fe|
        "#{fe.fei.expid}/#{fe.state}"
      })

    @engine.cancel(exp.fei)

    @engine.wait_for(:bob)

    assert_equal(
      %w[ 0/ 0_1/ ],
      @engine.ps(wfid).expressions.collect { |fe|
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

    @engine.register do
      alpha AlphaParticipant
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    @engine.pause(wfid)

    sleep 0.7 # give time to the pause propagation to reach the participant

    assert_equal(
      [ "dispatched:#{wfid}", "pause:#{wfid}" ],
      @tracer.to_a)

    @engine.resume(wfid)

    sleep 0.7 # give time to the resume propagation to reach the participant

    assert_equal(
      [ "dispatched:#{wfid}", "pause:#{wfid}", "resume:#{wfid}" ],
      @tracer.to_a)
  end

  def test_propagation_to_participant_when_participant_has_already_replied

    pdef = Ruote.define do
      alpha
    end

    @engine.register do
      alpha AlphaParticipant
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    @engine.pause(wfid)

    sleep 0.7 # give time to the pause propagation to reach the participant

    wi = @engine.ps(wfid).expressions.last.h.applied_workitem

    part = @engine.participant(:alpha.to_s)

    part.instance_eval { reply_to_engine(Ruote::Workitem.new(wi)) }

    @engine.wait_for(1)

    assert_equal(
      [ "dispatched:#{wfid}", "pause:#{wfid}" ],
      @tracer.to_a)

    @engine.resume(wfid)

    sleep 0.7 # give time to the resume propagation to reach the participant

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

    @engine.register do
      catchall
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    sequence = @engine.ps(wfid).expressions[1]

    @engine.pause(sequence.fei, :breakpoint => true)

    @engine.storage_participant.proceed(@engine.storage_participant.first)

    sleep 0.7

    assert_equal(
      [ nil, 'paused' ],
      @engine.ps(wfid).expressions.collect { |fexp| fexp.state })
  end

  def test_no_propagation_to_participant_when_breakpoint

    pdef = Ruote.define do
      alpha
    end

    @engine.register do
      alpha AlphaParticipant
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    alpha = @engine.ps(wfid).expressions.last

    @engine.pause(alpha.fei, :breakpoint => true)

    sleep 0.7 # give time to the pause propagation to reach the participant

    assert_equal([ "dispatched:#{wfid}" ], @tracer.to_a)

    @engine.resume(alpha.fei)

    sleep 0.7 # give time to the resume propagation to reach the participant

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

    @engine.register do
      catchall
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)
    @engine.wait_for(:bravo)

    exps = @engine.ps(wfid).expressions.select { |fexp|
      fexp.fei.expid.match(/^0_0_[01]$/)
    }

    exps.each { |fexp| @engine.pause(fexp.fei) }

    sleep 0.7

    assert_equal(
      [ nil, nil, 'paused', 'paused', 'paused' ],
      @engine.ps(wfid).expressions.collect { |fexp| fexp.state })

    @engine.resume(wfid)
      # won't resume the process, since the root is not paused

    sleep 0.4

    assert_equal(
      [ nil, nil, 'paused', 'paused', 'paused' ],
      @engine.ps(wfid).expressions.collect { |fexp| fexp.state })

    @engine.resume(wfid, :anyway => true)

    sleep 0.7

    assert_equal(
      [ nil, nil, nil, nil, nil ],
      @engine.ps(wfid).expressions.collect { |fexp| fexp.state })
  end
end

