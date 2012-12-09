
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
  end
end

