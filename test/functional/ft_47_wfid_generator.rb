
#
# testing ruote
#
# Sat Oct 23 14:22:15 JST 2010
#

require File.expand_path('../base', __FILE__)


class FtWfidGeneratorTest < Test::Unit::TestCase
  include FunctionalBase

  # an old test, brought back
  #
  def test_generate_unique_ids

    n = 10_000

    wfids = (1..n).collect { @dashboard.context.wfidgen.generate }

    assert_equal n, wfids.uniq.size
  end
end

