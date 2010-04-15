
#
# testing ruote
#
# Wed May 13 11:14:08 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


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
      participant :alpha
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    #noisy

    assert_trace 'alpha', pdef
  end

  def test_participant_exp_name

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    #noisy

    assert_trace 'alpha', pdef
  end

  def test_participant_exp_name_tree_rewriting

    pdef = Ruote.process_definition do
      alpha :tag => 'whatever'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    @engine.launch(pdef)
    wait_for(:alpha)

    assert_equal(
      ['participant', {'tag'=>'whatever', 'ref'=>'alpha'}, []],
      Ruote::Exp::FlowExpression.fetch(@engine.context, alpha.first.h.fei).tree)
  end

  def test_participant_if

    pdef = Ruote.process_definition do
      alpha
      bravo :if => 'false == true'
      charly
    end

    %w[ alpha bravo charly ].each do |pname|
      @engine.register_participant pname do |workitem|
        @tracer << "#{pname}\n"
      end
    end

    #noisy

    assert_trace %w[ alpha charly ], pdef
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

    part = @engine.register_participant :alpha do
      sleep 1
    end

    pdef = Ruote.process_definition do
      alpha
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

    fexp = ps.expressions.find { |fe|
      fe.class == Ruote::Exp::ParticipantExpression
    }

    assert_equal nil, fexp.dispatched
      # not yet 'dispatched'
  end
end

