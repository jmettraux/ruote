
#
# testing ruote
#
# Wed Dec  5 21:38:21 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtAwaitAttributeTest < Test::Unit::TestCase
  include FunctionalBase

  def test_left_tag

    pdef = Ruote.define do
      concurrence do
        sequence do
          echo 'b', :await => 'left_tag:x'
        end
        sequence :tag => 'x' do
          wait '1s'
          echo 'a'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal('terminated', r['action'])
    assert_equal(%w[ a b ], @tracer.to_a)

    assert_equal 0, @dashboard.storage.get_trackers['trackers'].size
  end

  def test_left_tag__implicit_in

    pdef = Ruote.define do
      concurrence do
        sequence do
          echo 'c', :await => 'tag:x'
        end
        sequence do
          echo 'a'
          wait 0.350
          echo 'b', :tag => 'x'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal('terminated', r['action'])
    assert_equal(%w[ a b c ], @tracer.to_a)

    assert_equal 0, @dashboard.storage.get_trackers['trackers'].size
  end

  def test_default_to_left_tag

    pdef = Ruote.define do
      concurrence do
        sequence do
          echo 'b', :await => 'x'
        end
        sequence :tag => 'x' do
          wait '.350'
          echo 'a'
        end
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal('terminated', r['action'])
    assert_equal(%w[ a b ], @tracer.to_a)

    assert_equal 0, @dashboard.storage.get_trackers['trackers'].size
  end
end

