
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

    @engine.wait_for(10)

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

  def test_error

    @engine.register_participant :alpha, Ruote::NullParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '1s: error'
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    ps = @engine.ps(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 2, ps.expressions.size

    assert_equal(
      '#<Ruote::ForcedError: error triggered from process definition>',
      ps.errors.first.message)
  end

  def test_error_message

    @engine.register_participant :alpha, Ruote::NullParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '1s: error it went wrong, 3d: nada'
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    ps = @engine.ps(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal '#<Ruote::ForcedError: it went wrong>', ps.errors[0].message
  end

  def test_redo_or_retry

    @engine.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '3s: retry'
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)
    @engine.wait_for(:alpha)

    assert_equal(
      'on_re_apply',
      @engine.storage_participant.first.params['_triggered'])
  end

  def test_undo_or_pass

    @engine.register_participant :alpha, Ruote::StorageParticipant
    @engine.register_participant :bravo, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '1s: pass'
      bravo
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:bravo)

    ps = @engine.ps(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
  end

  def test_jump_and_other_commands

    @engine.register '.+', Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      cursor do
        alpha :timers => '1s: jump to charly'
        bravo
        charly
      end
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    @engine.wait_for(:charly)
  end

  class MyParticipant
    include Ruote::LocalParticipant

    def consume(workitem)
      # do nothing
    end

    def rtimers(workitem)
      "2d: reminder"
    end
  end

  def test_participant_defined_timers

    @engine.register 'alpha', MyParticipant

    #@engine.noisy = true

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for(:alpha)

    alpha = @engine.ps(wfid).expressions.last

    pp alpha.h.timers.size

    assert_equal 1, alpha.h.timers.size
  end
end

