
#
# testing ruote
#
# Wed May 13 11:14:08 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant

    @dashboard.register_participant :alpha do |workitem|
      context.tracer << 'alpha'
    end

    pdef = Ruote.process_definition do
      participant :ref => 'alpha'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    sleep 0.300
      # give a chance to the 'dispatched' message for reaching us

    assert_equal 'alpha', @tracer.to_s
    assert_log_count(1) { |e| e['action'] == 'dispatch' }
    assert_log_count(1) { |e| e['action'] == 'receive' }
    assert_log_count(1) { |e| e['action'] == 'dispatched' }
  end

  def test_participant_att_text

    pdef = Ruote.process_definition do
      participant :bravo
    end

    @dashboard.register_participant :bravo do |workitem|
      tracer << 'bravo'
    end

    #noisy

    assert_trace 'bravo', pdef
  end

  def test_participant_exp_name

    pdef = Ruote.process_definition do
      charly
    end

    @dashboard.register_participant :charly do |workitem|
      tracer << 'charly'
    end

    #noisy

    assert_trace 'charly', pdef
  end

  def test_participant_exp_name_tree_rewriting

    pdef = Ruote.process_definition do
      delta :tag => 'whatever'
    end

    delta = @dashboard.register_participant :delta, Ruote::StorageParticipant

    @dashboard.launch(pdef)
    wait_for(:delta)

    assert_equal(
      ['participant', {'tag'=>'whatever', 'ref'=>'delta'}, []],
      Ruote::Exp::FlowExpression.fetch(@dashboard.context, delta.first.h.fei).tree)
  end

  def test_participant_if

    pdef = Ruote.process_definition do
      eecho
      fox :if => 'false == true'
      gamma
    end

    %w[ eecho fox gamma ].each do |pname|
      @dashboard.register_participant pname do |workitem|
        tracer << "#{workitem.participant_name}\n"
      end
    end

    #noisy

    assert_trace %w[ eecho gamma ], pdef
  end

  def test_participant_and_att_text

    pdef = Ruote.process_definition do
      notify 'commander of the left guard', :if => 'true'
      echo 'done.'
    end

    @dashboard.register_participant :notify do |wi, fe|
      #p fe.attribute_text
      stash[:atts] = fe.attributes
    end

    #noisy

    assert_trace 'done.', pdef

    assert_equal(
      { "commander of the left guard"=>nil, "if"=>"true", "ref"=>"notify" },
      stash[:atts])
  end

  def test_dispatched

    @dashboard.register 'toto', Ruote::StorageParticipant

    pdef = Ruote.process_definition do
      toto
    end

    wfid = @dashboard.launch(pdef)

    r = @dashboard.wait_for('dispatched')
    sleep 0.700

    fexp = @dashboard.ps(wfid).expressions.last

    assert_equal true, fexp.dispatched
    assert r.has_key?('fei')
    assert r.has_key?('workitem')
    assert r.has_key?('participant_name')
  end

  def test_not_dispatched

    @dashboard.register_participant :hotel do
      sleep 5
    end

    pdef = Ruote.process_definition do
      hotel
    end

    wfid = @dashboard.launch(pdef)

    #wait_for(:hotel)
    sleep 0.777
    sleep 1 # just for ruote-couch :-(

    ps = @dashboard.process(wfid)

    fexp = ps.expressions.find { |fe|
      fe.class == Ruote::Exp::ParticipantExpression
    }

    assert_equal nil, fexp.dispatched
      # not yet 'dispatched'
  end

  def test_tree

    require_json
    Rufus::Json.detect_backend

    @dashboard.register_participant :alice do |workitem|
      tracer << Rufus::Json.encode(workitem.params['__children__'])
    end

    pdef = Ruote.define do
      alice do
        on_error /500/ => 'this_or_${that}'
        whatever 'list' => '$f:list'
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(
      pdef,
      'that' => 'those',
      'list' => [ 1, 'two of ${that}', 3 ])

    @dashboard.wait_for(wfid)

    assert_equal(
      [ [ 'on_error', { '/500/' => 'this_or_those' }, [] ],
        [ 'whatever', { 'list' => [ 1, 'two of ${that}', 3 ] }, [] ] ],
      Rufus::Json.decode(@tracer.to_s))
  end
end

