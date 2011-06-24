
#
# testing ruote
#
# Thu Jun 25 13:31:26 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtReApplyTest < Test::Unit::TestCase
  include FunctionalBase

  PDEF = Ruote.process_definition do
    sequence do
      alpha
      echo 'done.'
    end
  end

  def test_re_apply

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha.proceed(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_cancel_and_re_apply

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha.proceed(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_update_expression_and_re_apply

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha.proceed(alpha.first)

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha.proceed(alpha.first)

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha.proceed(alpha.first)

    wait_for(wfid)

    assert_equal 'done for nada and nemo.', @tracer.to_s
  end

  def test_re_apply_with_new_tree

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

  def test_new_tree_and_process_status_current_tree

    #@engine.noisy = true

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.define { alpha })

    @engine.wait_for(:alpha)

    assert_equal(
      [ 'define', {}, [ [ 'participant', { 'ref' => 'alpha' }, [] ] ] ],
      @engine.process(wfid).current_tree)

    fei = @engine.storage_participant.first.fei

    @engine.re_apply(fei, :tree => [ 'bravo', {}, [] ])

    @engine.wait_for(:bravo)

    assert_equal(
      'bravo',
      @engine.storage_participant.first.participant_name)

    assert_equal(
      [ 'participant', { 'ref' => 'bravo', '_triggered' => 'on_re_apply' }, [] ],
      @engine.process(wfid).expressions.last.tree)

    assert_equal(
      [ 'define', {}, [ [ 'participant', { 'ref' => 'bravo', '_triggered' => 'on_re_apply' }, [] ] ] ],
      @engine.process(wfid).current_tree)
  end

  # Issue reported by Brett Anthoine
  #
  def test_re_apply_root

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.define { alpha })

    @engine.wait_for(:alpha)
    at0 = @engine.storage_participant.first.dispatched_at

    root = @engine.process(wfid).root_expression
    @engine.re_apply(root.fei)

    @engine.wait_for(:alpha)
    at1 = @engine.storage_participant.first.dispatched_at

    assert at1 > at0
  end

  def test_re_apply_define

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.define do
      sub0
      define 'sub0' do
        alpha
      end
    end)

    @engine.wait_for(:alpha)
    at0 = @engine.storage_participant.first.dispatched_at

    exp = @engine.process(wfid).expressions[1]

    @engine.re_apply(exp.fei)

    @engine.wait_for(:alpha)
    at1 = @engine.storage_participant.first.dispatched_at

    assert at1 > at0
  end

  # Making sure re_apply nukes errors
  #
  def test_re_apply_error

    #@engine.noisy = true

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.define do
      error "X"
    end)

    @engine.wait_for(wfid)

    fei = @engine.ps(wfid).expressions.last.fei

    @engine.re_apply(fei, :tree => [ 'alpha', {}, [] ])

    @engine.wait_for(:alpha)

    ps = @engine.ps(wfid)

    assert_equal 0, ps.errors.size
    assert_equal Ruote::Exp::ParticipantExpression, ps.expressions.last.class
  end
end

