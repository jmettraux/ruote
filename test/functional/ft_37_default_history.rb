
#
# testing ruote
#
# Mon Jan 24 11:11:43 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtDefaultHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_engine_has_history

    assert_not_nil @engine.context.history
    assert_not_nil @engine.history
  end

  def launch_processes(clear=true)

    @engine.history.clear! if clear

    @engine.register_participant 'alpha', Ruote::NullParticipant

    #puts; @engine.noisy = true

    pdef = Ruote.define do
      alpha
    end

    wfids = 2.times.collect { @engine.launch(pdef) }

    @engine.wait_for('dispatched')
    @engine.wait_for('dispatched')

    wfids
  end

  def test_all

    #noisy

    wfids = launch_processes

    assert_equal 10, @engine.history.all.size
  end

  def test_by_wfid

    wfids = launch_processes

    assert_equal 4, @engine.history.by_wfid(wfids[0]).size
    assert_not_nil @engine.history.by_wfid(wfids[0]).first['seen_at']

    assert_equal 4, @engine.history.by_wfid(wfids[1]).size
  end

  def test_clear!

    launch_processes

    assert_equal 10, @engine.history.all.size

    @engine.history.clear!

    assert_equal 0, @engine.history.all.size
  end

  def test_default_range

    range = @engine.history.range

    assert_equal Time, range[0].class
    assert_equal range[0], range[1]
  end

  def test_range

    launch_processes
    sleep 1
    launch_processes(false)

    range = @engine.history.range

    assert_not_equal range[0], range[1]
    assert range[0] < range[1]
  end

  def test_by_date

    launch_processes

    @engine.history.all.each { |msg| msg['seen_at'] = '1970-12-25' }

    launch_processes(false)

    assert_equal 21, @engine.history.all.size

    assert_equal 11, @engine.history.by_date(Time.now.utc).size
  end

  def test_wfids

    wfids = launch_processes

    assert_equal wfids.sort, @engine.history.wfids
  end
end

