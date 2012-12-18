
#
# testing ruote
#
# Tue Dec 18 07:35:02 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtTrackersTest < Test::Unit::TestCase
  include FunctionalBase

  def test_get_trackers

    flunk
  end

  def test_remove_fei_sid_tracker

    pdef = Ruote.define do
      concurrence do
        await :left_tag => 'nada0' do
          echo 'nada0'
        end
        await :left_tag => 'nada1' do
          echo 'nada1'
        end
        await :left_tag => 'nada2' do
          echo 'nada2'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    (1 + 3).times { @dashboard.wait_for('apply') }

    assert_equal 3, @dashboard.storage.get_trackers['trackers'].size

    ps = @dashboard.ps(wfid)
    fei = ps.leaves[0].fei
    hfei = ps.leaves[1].fei.h
    sfei = ps.leaves[2].fei.sid

    @dashboard.remove_tracker(fei)
    @dashboard.remove_tracker(hfei)
    @dashboard.remove_tracker(sfei)

    assert_equal 0, @dashboard.storage.get_trackers['trackers'].size
  end

  def test_remove_string_id_tracker

    flunk
  end
end

