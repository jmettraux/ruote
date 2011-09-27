
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
end

