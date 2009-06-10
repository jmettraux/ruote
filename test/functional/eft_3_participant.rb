
#
# Testing Ruote (OpenWFEru)
#
# Wed May 13 11:14:08 JST 2009
#

require File.dirname(__FILE__) + '/base'

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
    assert_equal 1, logger.log.select { |e| e[1] == :dispatching }.size
    assert_equal 1, logger.log.select { |e| e[1] == :received }.size
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

    alpha = @engine.register_participant :alpha, Ruote::JoinableHashParticipant

    @engine.launch(pdef)
    alpha.join

    assert_equal(
      ['participant', {'tag'=>'whatever', 'ref'=>'alpha'}, []],
      @engine.expstorage[alpha.first.fei].tree)
  end
end

