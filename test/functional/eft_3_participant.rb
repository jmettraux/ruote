
#
# testing ruote
#
# Wed May 13 11:14:08 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

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

    delta = @engine.register_participant :delta, Ruote::HashParticipant.new

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
        @tracer << "#{pname}\n"
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

    atts = nil

    @engine.register_participant :notify do |wi, fe|
      #p fe.attribute_text
      atts = fe.attributes
    end

    #noisy

    assert_trace 'done.', pdef

    assert_equal(
      { "commander of the left guard"=>nil, "if"=>"true", "ref"=>"notify" },
      atts)
  end

  def test_dispatched

    #@engine.register_participant :hotel do
    #  sleep 1
    #end
    @engine.register_participant :hotel, Ruote::NullParticipant

    pdef = Ruote.process_definition do
      hotel
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:hotel)

    ps = @engine.process(wfid)

    fexp = ps.expressions.find { |fe|
      fe.class == Ruote::Exp::ParticipantExpression
    }

    assert_equal nil, fexp.dispatched
      # not yet 'dispatched'
  end
end

