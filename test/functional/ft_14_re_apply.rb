
#
# testing ruote
#
# Thu Jun 25 13:31:26 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtReApplyTest < Test::Unit::TestCase
  include FunctionalBase

  PDEF = Ruote.process_definition do
    sequence do
      alpha
      echo 'done.'
    end
  end

  def test_re_apply

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(PDEF)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @dashboard.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @dashboard.re_apply(stalled_exp.fei)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_equal id0, alpha.first.object_id

    alpha.proceed(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_cancel_and_re_apply

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(PDEF)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @dashboard.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @dashboard.re_apply(stalled_exp.fei)

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_equal id0, alpha.first.object_id

    alpha.proceed(alpha.first)

    wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
  end

  def test_update_expression_and_re_apply

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(PDEF)
    wait_for(:alpha)

    sleep 0.350 # threaded dispatch

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @dashboard.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    stalled_exp.update_tree([
      'participant', { 'ref' => 'alpha', 'activity' => 'mow lawn' }, [] ])
    #p [ :stalled, stalled_exp.h['_rev'] ]
    stalled_exp.persist

    @dashboard.re_apply(stalled_exp.fei)

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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @dashboard.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @dashboard.re_apply(stalled_exp.fei, :fields => { 'x' => 'nada' })

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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(pdef, { 'y' => 'nemo' })
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @dashboard.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @dashboard.re_apply(stalled_exp.fei, :merge_in_fields => { 'x' => 'nada' })

    wait_for(:alpha)

    assert_equal 1, alpha.size
    assert_not_equal id0, alpha.first.object_id

    alpha.proceed(alpha.first)

    wait_for(wfid)

    assert_equal 'done for nada and nemo.', @tracer.to_s
  end

  def test_re_apply_with_new_tree

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @dashboard.launch(PDEF)
    wait_for(:alpha)

    id0 = alpha.first.object_id

    # ... flow stalled ...

    ps = @dashboard.process(wfid)

    stalled_exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_0' }

    @dashboard.re_apply(
      stalled_exp.fei, :tree => [ 'echo', { 're_applied' => nil }, [] ])

    wait_for(wfid)

    assert_equal "re_applied\ndone.", @tracer.to_s
  end

  def test_new_tree_and_process_status_current_tree

    #@dashboard.noisy = true

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define { alpha })

    @dashboard.wait_for(:alpha)

    assert_equal(
      [ 'define', {}, [ [ 'participant', { 'ref' => 'alpha' }, [] ] ] ],
      @dashboard.process(wfid).current_tree)

    fei = @dashboard.storage_participant.first.fei

    @dashboard.re_apply(fei, :tree => [ 'bravo', {}, [] ])

    @dashboard.wait_for(:bravo)

    assert_equal(
      'bravo',
      @dashboard.storage_participant.first.participant_name)

    assert_equal(
      [ 'participant', { 'ref' => 'bravo', '_triggered' => 'on_re_apply' }, [] ],
      @dashboard.process(wfid).expressions.last.tree)

    assert_equal(
      [ 'define', {}, [ [ 'participant', { 'ref' => 'bravo', '_triggered' => 'on_re_apply' }, [] ] ] ],
      @dashboard.process(wfid).current_tree)
  end

  # Issue reported by Brett Anthoine
  #
  def test_re_apply_root

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define { alpha })

    @dashboard.wait_for(:alpha)
    at0 = @dashboard.storage_participant.first.dispatched_at

    root = @dashboard.process(wfid).root_expression
    @dashboard.re_apply(root.fei)

    @dashboard.wait_for(:alpha)
    at1 = @dashboard.storage_participant.first.dispatched_at

    assert at1 > at0
  end

  def test_re_apply_define

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define do
      sub0
      define 'sub0' do
        alpha
      end
    end)

    @dashboard.wait_for(:alpha)
    at0 = @dashboard.storage_participant.first.dispatched_at

    exp = @dashboard.process(wfid).expressions[1]

    @dashboard.re_apply(exp.fei)

    @dashboard.wait_for(:alpha)
    at1 = @dashboard.storage_participant.first.dispatched_at

    assert at1 > at0
  end

  def test_re_apply_chunk

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define do
      alpha
    end)

    @dashboard.wait_for(:alpha)

    at0 = @dashboard.storage_participant.first.dispatched_at

    exp = @dashboard.process(wfid).expressions.last

    t = Ruote.tree do
      alpha :take => two
    end

    @dashboard.re_apply(exp)
    @dashboard.wait_for(:alpha)

    wi1 = @dashboard.storage_participant.first
    at1 = wi1.dispatched_at

    assert at1 > at0
    assert_equal 'on_re_apply', wi1.params['_triggered']
  end

  # Making sure re_apply nukes errors
  #
  def test_re_apply_error

    #@dashboard.noisy = true

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define do
      error "X"
    end)

    @dashboard.wait_for(wfid)

    fei = @dashboard.ps(wfid).expressions.last.fei

    @dashboard.re_apply(fei, :tree => [ 'alpha', {}, [] ])

    @dashboard.wait_for(:alpha)

    ps = @dashboard.ps(wfid)

    assert_equal 0, ps.errors.size
    assert_equal Ruote::Exp::ParticipantExpression, ps.expressions.last.class
  end
end

