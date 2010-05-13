
#
# testing ruote
#
# Thu Jun 25 13:31:26 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtReApplyTest < Test::Unit::TestCase
  include FunctionalBase

  PDEF = Ruote.process_definition do
    sequence do
      alpha
      echo 'done.'
    end
  end

  def test_re_apply

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(PDEF)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @engine.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @engine.re_apply(stalled_exp.fei)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_equal id0, alpha.first.object_id

    alpha.reply(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_cancel_and_re_apply

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(PDEF)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @engine.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @engine.re_apply(stalled_exp.fei)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_equal id0, alpha.first.object_id

    alpha.reply(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_update_expression_and_re_apply

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(PDEF)
    wait_for(:alpha)

    sleep 0.350 # threaded dispatch

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @engine.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    stalled_exp.update_tree([
      'participant', { 'ref' => 'alpha', 'activity' => 'mow lawn' }, [] ])
    #p [ :stalled, stalled_exp.h['_rev'] ]
    stalled_exp.persist

    @engine.re_apply(stalled_exp.fei)

    wait_for(:alpha)

    assert_equal 'mow lawn', alpha.first.fields['params']['activity']

    alpha.reply(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_re_apply_with_new_workitem_fields

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo 'done for ${f:x}.'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @engine.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @engine.re_apply(stalled_exp.fei, :fields => { 'x' => 'nada' })

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_equal id0, alpha.first.object_id

    alpha.reply(alpha.first)

    wait_for(wfid)

    assert_equal 'done for nada.', @tracer.to_s
  end

  def test_re_apply_with_merged_workitem_fields

    pdef = Ruote.process_definition do
      sequence do
        alpha
        echo 'done for ${f:x} and ${f:y}.'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef, { 'y' => 'nemo' })
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @engine.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @engine.re_apply(stalled_exp.fei, :merge_in_fields => { 'x' => 'nada' })

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_equal id0, alpha.first.object_id

    alpha.reply(alpha.first)

    wait_for(wfid)

    assert_equal 'done for nada and nemo.', @tracer.to_s
  end

  def test_re_apply_with_new_tree

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(PDEF)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @engine.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @engine.re_apply(
      stalled_exp.fei, :tree => [ 'echo', { 're_applied' => nil }, [] ])

    wait_for(wfid)

    assert_equal "re_applied\ndone.", @tracer.to_s
  end
end

