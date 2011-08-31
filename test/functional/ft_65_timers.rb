
#
# testing ruote
#
# Mon Aug 15 20:43:11 JST 2011
#
# Right before the international date change line
#

require File.expand_path('../base', __FILE__)


class FtTimersTest < Test::Unit::TestCase
  include FunctionalBase

  def test_single_timeout

    pdef = Ruote.process_definition do
      alpha :timers => '1d: timeout'
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    assert_equal(
      1, @engine.storage.get_many('schedules').size)
    assert_equal(
      'cancel', @engine.storage.get_many('schedules').first['msg']['action'])

    ps = @engine.ps(wfid)

    assert_not_nil ps.expressions.last.h.timers
    assert_equal 1, ps.expressions.last.h.timers.size
    assert_match /^at-/, ps.expressions.last.h.timers.first.first
    assert_equal 'timeout', ps.expressions.last.h.timers.first.last
  end

  def test_reminders

    pdef = Ruote.process_definition do
      alpha :timers => '1s: remind, 2s: remind'
      define 'remind' do
        echo 'reminder'
      end
    end

    @engine.register_participant :alpha, Ruote::NullParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(20)

    assert_equal %w[ reminder reminder ], @tracer.to_a
  end

  def test_expid

    # same expid as expression sporting the :timers

    pdef = Ruote.process_definition do
      alpha :timers => '1s: remind'
    end

    @engine.register_participant :alpha, Ruote::NullParticipant

    @engine.register_participant :remind do |workitem|
      @tracer << workitem.fei.expid
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(9)

    assert_equal '0_0', @tracer.to_s
  end

  def test_cancelling

    pdef = Ruote.process_definition do
      alpha :timers => '1d: remind'
      bravo
    end

    @engine.register_participant /alpha|bravo/, Ruote::StorageParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)
    @engine.wait_for(1)

    fei = @engine.ps(wfid).expressions.last.fei

    @engine.cancel(fei)

    @engine.wait_for(:bravo)
    @engine.wait_for(1)

    ps = @engine.ps(wfid)

    assert_equal 0, ps.schedules.size
  end

  def test_flanks

    pdef = Ruote.process_definition do
      alpha :timers => '1s: reminder'
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :reminder, Ruote::NullParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:reminder)
    @engine.wait_for(1)

    ps = @engine.ps(wfid)

    alpha = ps.expressions.find { |e| e.h.participant_name == 'alpha' }

    assert_equal [ '0_0' ], alpha.h.flanks.collect { |fei| fei['expid'] }
  end

  def test_cancelling_running_side

    pdef = Ruote.process_definition do
      alpha :timers => '1s: reminder'
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :reminder, Ruote::NullParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:reminder)
    @engine.wait_for(1)

    ps = @engine.ps(wfid)

    assert_equal 3, ps.expressions.size

    alpha = ps.expressions.find { |e| e.h.participant_name == 'alpha' }

    @engine.cancel(alpha)

    @engine.wait_for(wfid)

    assert_nil @engine.ps(wfid)
  end
end

