
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

  def test_propagation_to_participant

    flunk
  end
end

