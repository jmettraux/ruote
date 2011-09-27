
#
# testing ruote
#
# Wed Aug 17 08:29:13 JST 2011
#
# Santa Barbara
#

require File.expand_path('../base', __FILE__)


class EftStallTest < Test::Unit::TestCase
  include FunctionalBase

  def test_no_operation

    pdef = Ruote.define do
      stall
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    sleep 0.750

    ps = @dashboard.ps(wfid)

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal 'stall', ps.expressions.last.name
  end
end

