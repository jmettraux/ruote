
#
# testing ruote
#
# Sat Oct 23 14:22:15 JST 2010
#

require File.expand_path('../base', __FILE__)
require_json


class FtWfidGeneratorTest < Test::Unit::TestCase
  include FunctionalBase

  # an old test, brought back
  #
  def test_generate_unique_ids

    n = 10_000

    wfids = (1..n).collect { @dashboard.context.wfidgen.generate }

    assert_equal n, wfids.uniq.size
  end

  def test_launcher_decides_wfid

    Rufus::Json.detect_backend

    i = '20120315-0557-nada'

    wfid = @dashboard.launch(Ruote.define { echo 'a' }, :wfid => i)
    r = @dashboard.wait_for(wfid)

    assert_equal i, wfid
    assert_equal [ 'wfid' ], r['workitem']['fields'].keys

    assert_equal 'terminated', r['action']
  end
end

