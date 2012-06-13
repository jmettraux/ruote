
#
# testing ruote
#
# Wed Jun 13 13:50:56 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtRaiseMsgTest < Test::Unit::TestCase
  include FunctionalBase

  class FaultyParticipant
    include Ruote::LocalParticipant

    def on_workitem

      @context.storage.put_msg(
        'raise',
        'fei' => workitem.h.fei,
        'wfid' => workitem.h.fei['wfid'],
        'msg' => {
          'fei' => workitem.h.fei,
          'wfid' => workitem.h.fei['wfid'],
          'workitem' => workitem.h },
        'error' => {
          'class' => 'ArgumentError',
          'message' => "that's very wrong",
          'trace' => [ "local.rb:126:in `whatever'" ] })

      # do not reply
    end
  end

  def test_raise_via_put_msg

    # participant doesn't reply but places "raise" msg

    @dashboard.register :faulty, FaultyParticipant

    pdef = Ruote.define do
      faulty
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for('error_intercepted')

    assert_equal 'ArgumentError', r['error']['class']
    assert_equal "that's very wrong", r['error']['message']
    assert_equal "local.rb:126:in `whatever'", r['error']['trace'].join

    ps = @dashboard.ps(wfid)

    assert_equal(
      1, ps.errors.size)
    assert_equal(
      "raised: ArgumentError: that's very wrong", ps.errors.first.message)
  end

  class RaisyParticipant
    include Ruote::LocalParticipant

    def on_workitem

      raise "I don't like pasta!"

    rescue => err

      @context.error_handler.msg_raise(
        { 'fei' => workitem.h.fei,
          'wfid' => workitem.h.fei['wfid'],
          'workitem' => workitem.h },
        err)

      # do not reply
    end
  end

  def test_raise_via_raise_msg

    # participant doesn't reply but places "raise" msg

    @dashboard.register :raisy, RaisyParticipant

    pdef = Ruote.define do
      raisy
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for('error_intercepted')

    assert_equal 'RuntimeError', r['error']['class']
    assert_equal "I don't like pasta!", r['error']['message']
    assert_equal Array, r['error']['trace'].class

    ps = @dashboard.ps(wfid)

    assert_equal(
      1, ps.errors.size)
    assert_equal(
      "raised: RuntimeError: I don't like pasta!", ps.errors.first.message)
  end
end

