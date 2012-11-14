
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

    wfid = @dashboard.launch(pdef, 'message' => 'hello planet')
    r = @dashboard.wait_for('dispatched')

    adef = Ruote.define do
      echo '${v:message}'
      echo '${f:message}'
    end

    fei = @dashboard.attach(r['fei'], adef)
    r = @dashboard.wait_for('ceased')

    ps = @dashboard.ps(wfid)

    assert_equal '0_1_0', fei.expid
    assert_equal wfid, fei.wfid

    assert_equal "hello world\nhello planet", @tracer.to_s

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal 1, ps.stored_workitems.size
  end

  def test_attach_fields_option

    @dashboard.register '.+', Ruote::StorageParticipant

    pdef = Ruote.define do
      set 'v:message' => 'hello world'
      bravo
    end

    wfid = @dashboard.launch(pdef, 'message' => 'hello planet')
    r = @dashboard.wait_for('dispatched')

    adef = Ruote.define do
      echo '${v:message}'
      echo '${f:message}'
    end

    fei = @dashboard.attach(r['fei'], adef, :fields => { 'message' => 'nada' })
    r = @dashboard.wait_for('ceased')
    #ps = @dashboard.ps(wfid)

    assert_equal "hello world\nnada", @tracer.to_s
  end

  # Well, let's not test those 3 lines of code.
  #
  #def test_attach_merge_fields_option
  #end

  def test_attach_with_fe

    @dashboard.register '.+', Ruote::StorageParticipant

    pdef = Ruote.define do
      set 'v:message' => 'hello world'
      bravo
    end

    wfid = @dashboard.launch(pdef, 'message' => 'hello planet')
    r = @dashboard.wait_for('dispatched')

    adef = Ruote.define do
      echo '${v:message}'
      echo '${f:message}'
    end

    fe = @dashboard.ps(wfid).expressions.last
    fei = @dashboard.attach(fe.h, adef)
    r = @dashboard.wait_for('ceased')

    ps = @dashboard.ps(wfid)

    assert_equal '0_1_0', fei.expid
    assert_equal wfid, fei.wfid

    assert_equal "hello world\nhello planet", @tracer.to_s

    assert_equal 0, ps.errors.size
    assert_equal 2, ps.expressions.size
    assert_equal 1, ps.stored_workitems.size
  end

  def test_attach_with_error

    @dashboard.register '.+', Ruote::NullParticipant

    pdef = Ruote.define do
      nancy
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for('dispatched')

    adef = Ruote.define do
      error 'failing in style'
    end

    fei = @dashboard.attach(r['fei'], adef)
    r = @dashboard.wait_for('error_intercepted')

    ps = @dashboard.ps(wfid)

    assert_equal 1, ps.errors.size

    @dashboard.cancel(fei)
    r = @dashboard.wait_for('ceased')

    ps = @dashboard.ps(wfid)

    assert_equal 0, ps.errors.size
  end
end

