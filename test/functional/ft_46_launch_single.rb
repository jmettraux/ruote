
#
# testing ruote
#
# Sat Sep 25 23:24:16 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


class FtLaunchSingleTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_name_singles_are_rejected

    assert_raise ArgumentError do
      @engine.launch_single(Ruote.process_definition do
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

    wfid = @engine.launch_single(pdef)

    assert_equal(
      wfid,
      @engine.storage.get('variables', 'singles')['h']['unique_process'].first)

    @engine.wait_for(2)

    assert_not_nil @engine.process(wfid)

    wfid1 = @engine.launch_single(pdef)

    sleep 1

    assert_equal wfid, wfid1
    assert_equal 1, @engine.processes.size
  end

  # Fighting the issue reported by Gonzalo in
  # http://groups.google.com/group/openwferu-users/browse_thread/thread/fa9c8b414f355f79
  #
  def test_launch_single_cancel_launch_single

    pdef = Ruote.process_definition 'unique_process' do
      wait '2y'
      echo 'over.'
    end

    wfid0 = @engine.launch_single(pdef)

    sleep 0.700
    assert_not_nil @engine.process(wfid0)

    @engine.cancel(wfid0)

    sleep 0.700
    assert_nil @engine.process(wfid0)

    sleep 1.400
    wfid1 = @engine.launch_single(pdef)

    sleep 0.700
    assert_not_equal wfid0, wfid1
    assert_nil @engine.process(wfid0)
    assert_not_nil @engine.process(wfid1)
  end
end

