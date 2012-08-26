
#
# testing ruote
#
# Sat Sep 25 23:24:16 JST 2010
#

require File.expand_path('../base', __FILE__)


class FtLaunchSingleTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_name_singles_are_rejected

    assert_raise ArgumentError do
      @dashboard.launch_single(Ruote.process_definition do
        wait '2y'
        echo 'over.'
      end)
    end
  end

  def test_launch_single

    pdef = Ruote.process_definition 'unique_process' do
      wait '2y'
      echo 'over.'
    end

    #noisy

    wfid = @dashboard.launch_single(pdef)

    assert_equal(
      wfid,
      @dashboard.storage.get('variables', 'singles')['h']['unique_process'].first)

    @dashboard.wait_for(2)

    assert_not_nil @dashboard.process(wfid)

    wfid1 = @dashboard.launch_single(pdef)

    sleep 1

    assert_equal wfid, wfid1
    assert_equal 1, @dashboard.processes.size
  end

  # Fighting the issue reported by Gonzalo in
  # http://groups.google.com/group/openwferu-users/browse_thread/thread/fa9c8b414f355f79
  #
  def test_launch_single_cancel_launch_single

    pdef = Ruote.process_definition 'unique_process' do
      wait '2y'
      echo 'over.'
    end

    #noisy

    wfid0 = @dashboard.launch_single(pdef)

    sleep 0.700
    assert_not_nil @dashboard.process(wfid0)

    @dashboard.cancel(wfid0)

    @dashboard.wait_for('terminated')
    assert_nil @dashboard.process(wfid0)

    sleep 0.700
    wfid1 = @dashboard.launch_single(pdef)

    @dashboard.wait_for('apply')

    assert_not_equal wfid0, wfid1
    assert_nil @dashboard.process(wfid0)
    assert_not_nil @dashboard.process(wfid1)
  end
end

