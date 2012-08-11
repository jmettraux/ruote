
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

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    assert_equal(
      1, @dashboard.storage.get_many('schedules').size)
    assert_equal(
      'cancel', @dashboard.storage.get_many('schedules').first['msg']['action'])

    ps = @dashboard.ps(wfid)

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

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(20)

    assert_equal %w[ reminder reminder ], @tracer.to_a
  end

  def test_expid

    # same expid as expression sporting the :timers

    pdef = Ruote.process_definition do
      alpha :timers => '1s: remind'
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    @dashboard.register_participant :remind do |workitem|
      tracer << workitem.fei.expid
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(10)

    assert_equal '0_0', @tracer.to_s
  end

  def test_cancelling

    pdef = Ruote.process_definition do
      alpha :timers => '1d: remind'
      bravo
    end

    @dashboard.register_participant /alpha|bravo/, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(1)

    fei = @dashboard.ps(wfid).expressions.last.fei

    @dashboard.cancel(fei)

    @dashboard.wait_for(:bravo)
    @dashboard.wait_for(1)

    ps = @dashboard.ps(wfid)

    assert_equal 0, ps.schedules.size
  end

  def test_flanks

    pdef = Ruote.process_definition do
      alpha :timers => '1s: reminder'
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    @dashboard.register_participant :reminder, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:reminder)
    @dashboard.wait_for(1)

    ps = @dashboard.ps(wfid)

    alpha = ps.expressions.find { |e| e.h.participant_name == 'alpha' }

    assert_equal [ '0_0' ], alpha.h.flanks.collect { |fei| fei['expid'] }
  end

  def test_cancelling_running_side

    pdef = Ruote.process_definition do
      alpha :timers => '1s: reminder'
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    @dashboard.register_participant :reminder, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:reminder)
    @dashboard.wait_for(1)

    ps = @dashboard.ps(wfid)

    assert_equal 3, ps.expressions.size

    alpha = ps.expressions.find { |e| e.h.participant_name == 'alpha' }

    @dashboard.cancel(alpha)

    @dashboard.wait_for(wfid)

    assert_nil @dashboard.ps(wfid)
  end

  def test_error

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '1s: error'
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    ps = @dashboard.ps(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 2, ps.expressions.size

    assert_equal(
      '#<Ruote::ForcedError: timer induced error ("1s: error")>',
      ps.errors.first.message)
  end

  def test_error_message

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '1s: error it went wrong, 3d: nada'
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    ps = @dashboard.ps(wfid)

    assert_equal 1, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal '#<Ruote::ForcedError: it went wrong>', ps.errors[0].message
  end

  def test_redo_or_retry

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '3s: retry'
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(:alpha)

    assert_equal(
      'on_re_apply',
      @dashboard.storage_participant.first.params['_triggered'])
  end

  def test_undo_or_pass

    @dashboard.register_participant :alpha, Ruote::StorageParticipant
    @dashboard.register_participant :bravo, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '1s: pass'
      bravo
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:bravo)

    ps = @dashboard.ps(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
  end

  def test_jump_and_other_commands

    @dashboard.register '.+', Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      cursor do
        alpha :timers => '1s: jump to charly'
        bravo
        charly
      end
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:charly)
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

    @dashboard.register 'alpha', MyParticipant

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    @dashboard.wait_for(:alpha)

    alpha = @dashboard.ps(wfid).expressions.last

    assert_equal 1, alpha.h.timers.size
  end

  def test_bad_syntax

    pdef = Ruote.process_definition do
      alpha :timers => '1x: timeout'
    end

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('error_intercepted')

    err = @dashboard.ps(wfid).errors.first

    assert_equal "#<ArgumentError: unknown time char 'x'>", err.message
  end

  def test_process_status_and_timers

    @dashboard.register :alpha, Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      alpha :timers => '3h: x, 1d: timeout'
    end

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('launch')
    @dashboard.wait_for('dispatched')

    ps = @dashboard.ps(wfid).inspect

    assert_match /apply\n\s+\*\* no target \*\*/, ps
    assert_match /cancel\n\s+0_0!/, ps
  end
end

