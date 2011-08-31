
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

    pdef = Ruote.process_definition do
      participant :ref => 'alpha'
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    #noisy

    assert_trace 'alpha', pdef

    assert_log_count(1) { |e| e['action'] == 'dispatch' }
    assert_log_count(1) { |e| e['action'] == 'dispatched' }
    assert_log_count(1) { |e| e['action'] == 'receive' }
  end

  def test_participant_att_text

    pdef = Ruote.process_definition do
      participant :bravo
    end

    @engine.register_participant :bravo do |workitem|
      @tracer << 'bravo'
    end

    #noisy

    assert_trace 'bravo', pdef
  end

  def test_participant_exp_name

    pdef = Ruote.process_definition do
      charly
    end

    @engine.register_participant :charly do |workitem|
      @tracer << 'charly'
    end

    #noisy

    assert_trace 'charly', pdef
  end

  def test_participant_exp_name_tree_rewriting

    pdef = Ruote.process_definition do
      delta :tag => 'whatever'
    end

    delta = @engine.register_participant :delta, Ruote::StorageParticipant

    @engine.launch(pdef)
    wait_for(:delta)

    assert_equal(
      ['participant', {'tag'=>'whatever', 'ref'=>'delta'}, []],
      Ruote::Exp::FlowExpression.fetch(@engine.context, delta.first.h.fei).tree)
  end

  def test_participant_if

    pdef = Ruote.process_definition do
      eecho
      fox :if => 'false == true'
      gamma
    end

    %w[ eecho fox gamma ].each do |pname|
      @engine.register_participant pname do |workitem|
        @tracer << "#{workitem.participant_name}\n"
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

    @engine.register_participant :notify do |wi, fe|
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

    @engine.register_participant :hotel do
      sleep 5
    end

    pdef = Ruote.process_definition do
      hotel
    end

    #noisy

    wfid = @engine.launch(pdef)

    #wait_for(:hotel)
    sleep 0.777
    sleep 1 # just for ruote-couch :-(

    ps = @engine.process(wfid)

    fexp = ps.expressions.find { |fe|
      fe.class == Ruote::Exp::ParticipantExpression
    }

    assert_equal nil, fexp.dispatched
      # not yet 'dispatched'
  end

  def test_tree

    require_json
    Rufus::Json.detect_backend

    @engine.register_participant :alice do |workitem|
      @tracer << Rufus::Json.encode(workitem.params['__children__'])
    end

    pdef = Ruote.define do
      alice do
        on_error /500/ => 'this_or_${that}'
        whatever 'list' => '$f:list'
      end
    end

    #@engine.noisy = true

    wfid = @engine.launch(
      pdef,
      'that' => 'those',
      'list' => [ 1, 'two of ${that}', 3 ])

    @engine.wait_for(wfid)

    assert_equal(
      [ [ 'on_error', { '/500/' => 'this_or_those' }, [] ],
        [ 'whatever', { 'list' => [ 1, 'two of ${that}', 3 ] }, [] ] ],
      Rufus::Json.decode(@tracer.to_s))
  end
end

