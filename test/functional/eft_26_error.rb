
#
# testing ruote
#
# Tue Sep 15 19:26:33 JST 2009
#

require File.expand_path('../base', __FILE__)


class EftErrorTest < Test::Unit::TestCase
  include FunctionalBase

  PDEF0 = Ruote.process_definition :name => 'test' do
    sequence do
      echo 'a'
      error
      echo 'b'
    end
  end

  def test_error

    #noisy

    wfid = @dashboard.launch(PDEF0)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    assert_equal(
      'a', @tracer.to_s)
    assert_equal(
      1, ps.errors.size)
    assert_equal(
      '#<Ruote::ForcedError: error triggered from process definition>',
      ps.errors.first.message)
  end

  def test_error_replay

    #noisy

    wfid = @dashboard.launch(PDEF0)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    @dashboard.replay_at_error(ps.errors.first)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
    assert_equal "a\nb", @tracer.to_s
  end

  def test_error_cancel

    wfid = @dashboard.launch(PDEF0)

    wait_for(wfid)

    ps = @dashboard.process(wfid)

    sequence = ps.expressions.find { |fe| fe.fei.expid == '0_0' }

    @dashboard.cancel_expression(sequence.fei)

    wait_for(wfid)

    assert_nil @dashboard.process(wfid)
    assert_equal 'a', @tracer.to_s
  end

  #
  # Error re-raising, recall an error stored in a field or a variable.
  # If the value is nil, don't re-raise.

  def test_error_re

    pdef =
      Ruote.define do
        define 'handler' do
          set 'f:err' => '$f:__error__'
        end
        sequence :on_error => 'handler' do
          error 'fail!'
        end
        error :re => '$f:err'
      end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'fail!', r['msg']['workitem']['fields']['err']['message']
    assert_equal 'fail!', r['error']['message']
  end

  # When there is no value for the field/variable, don't raise.
  #
  def test_error_no_re

    pdef =
      Ruote.define do
        error :re => '$f:err'
      end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal('terminated', r['action'])
  end
end

