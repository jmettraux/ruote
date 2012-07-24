
#
# testing ruote
#
# Mon Jan 24 11:11:43 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtDefaultHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_engine_has_history

    assert_not_nil @dashboard.context.history
    assert_not_nil @dashboard.history
  end

  def launch_processes(clear=true)

    if clear
      @dashboard.history.clear!
      sleep 0.050
      @dashboard.history.clear!
    end

    @dashboard.register_participant 'alpha', Ruote::NullParticipant

    #puts; @dashboard.noisy = true

    pdef = Ruote.define do
      alpha
    end

    wfids = 2.times.collect { @dashboard.launch(pdef) }

    @dashboard.wait_for('dispatched')
    @dashboard.wait_for('dispatched')

    wfids
  end

  def test_all

    #noisy

    wfids = launch_processes

    assert_equal 9, @dashboard.history.reject { |m| m['action'] == 'noop' }.size
  end

  def test_by_wfid

    wfids = launch_processes

    assert_equal 4, @dashboard.history.by_wfid(wfids[0]).size
    assert_not_nil @dashboard.history.by_wfid(wfids[0]).first['seen_at']

    assert_equal 4, @dashboard.history.by_wfid(wfids[1]).size
  end

  def test_clear!

    launch_processes

    assert_equal 9, @dashboard.history.reject { |m| m['action'] == 'noop' }.size

    @dashboard.history.clear!

    assert_equal 0, @dashboard.history.all.size
  end

  def test_default_range

    range = @dashboard.history.range

    assert_equal Time, range[0].class
    assert_equal range[0], range[1]
  end

  def test_range

    launch_processes
    sleep 1
    launch_processes(false)

    range = @dashboard.history.range

    assert_not_equal range[0], range[1]
    assert range[0] < range[1]
  end

  def test_by_date

    launch_processes

    @dashboard.history.all.each { |msg| msg['seen_at'] = '1970-12-25' }

    launch_processes(false)

    assert_equal(
      18,
      @dashboard.history.reject { |m|
        m['action'] == 'noop'
      }.size)
    assert_equal(
      9,
      @dashboard.history.by_date(Time.now.utc).reject { |m|
        m['action'] == 'noop'
      }.size)
  end

  def test_wfids

    wfids = launch_processes

    assert_equal wfids.sort, @dashboard.history.wfids
  end
end

