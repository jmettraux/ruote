
#
# testing ruote
#
# Wed Oct  3 09:22:39 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtAttachTest < Test::Unit::TestCase
  include FunctionalBase

  def test_attach

    @dashboard.register '.+', Ruote::StorageParticipant

    pdef = Ruote.define do
      set 'v:message' => 'hello world'
      bravo
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('dispatched')

    adef = Ruote.define do
      echo '${v:message}'
    end

    fei = @dashboard.attach(r['fei'], adef)
    r = @dashboard.wait_for('ceased')

    ps = @dashboard.ps(wfid)

    assert_equal '0', fei.expid
    assert_equal wfid, fei.wfid

    assert_equal 'hello world', @tracer.to_s

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal 1, ps.stored_workitems.size
  end
end

