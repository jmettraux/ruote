
#
# testing ruote
#
# Tue Sep 15 19:26:33 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

    wfid = @engine.launch(PDEF0)

    wait_for(wfid)

    ps = @engine.process(wfid)

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

    wfid = @engine.launch(PDEF0)

    wait_for(wfid)

    ps = @engine.process(wfid)

    @engine.replay_at_error(ps.errors.first)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal "a\nb", @tracer.to_s
  end

  def test_error_cancel

    wfid = @engine.launch(PDEF0)

    wait_for(wfid)

    ps = @engine.process(wfid)

    sequence = ps.expressions.find { |fe| fe.fei.expid == '0_0' }

    @engine.cancel_expression(sequence.fei)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
    assert_equal 'a', @tracer.to_s
  end
end

