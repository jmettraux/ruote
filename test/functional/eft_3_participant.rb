
#
# Testing Ruote (OpenWFEru)
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

    assert_trace pdef, 'alpha'

    assert_log_count(1) { |e| e[1] == :received }

    sleep 0.050
    assert_log_count(1) { |e| e[1] == :dispatched } # arrives a tad later...
  end

  def test_participant_att_text

    pdef = Ruote.process_definition do
      participant :alpha
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    #noisy

    assert_trace pdef, 'alpha'
  end

  def test_participant_exp_name

    pdef = Ruote.process_definition do
      alpha
    end

    @engine.register_participant :alpha do |workitem|
      @tracer << 'alpha'
    end

    #noisy

    assert_trace pdef, 'alpha'
  end

  def test_participant_exp_name_tree_rewriting

    pdef = Ruote.process_definition do
      alpha :tag => 'whatever'
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    @engine.launch(pdef)
    wait_for(:alpha)

    assert_equal(
      ['participant', {'tag'=>'whatever', 'ref'=>'alpha'}, []],
      @engine.expstorage[alpha.first.fei].tree)
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

    assert_trace pdef, %w[ alpha charly ]
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

    assert_trace pdef, 'done.'

    assert_equal(
      { "commander of the left guard"=>nil, "if"=>"true", "ref"=>"notify" },
      atts)
  end
end

