
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Apr  8 18:33:11 JST 2008
#

require 'rubygems'

require 'test/unit'

require 'openwfe/engine'


class PsRepresentationTest < Test::Unit::TestCase

  def setup

    @engine = OpenWFE::Engine.new :definition_in_launchitem_allowed => true
  end

  def teardown

    @engine.stop if @engine
  end

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      alpha
      bravo
    end
  end

  def test_0

    @engine.register_participant "alpha", OpenWFE::NullParticipant

    fei = @engine.launch Test0

    sleep 0.350

    ps = @engine.process_stack(fei)

    #p ps.representation

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sequence", {}, [["alpha", {"ref"=>"alpha"}, []], ["bravo", {}, []]]]]],
      ps.tree)

    #
    # change process instance (charly instead of bravo)

    #puts ps.collect { |fexp| fexp.fei.to_s }.join("\n")

    esequence = ps.find { |fexp| fexp.fei.expid == '0.0' }

    @engine.update_raw_expression esequence.fei, ['charly', {}, []], 1

    ps = @engine.process_stack(fei)

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sequence", {}, [["alpha", {"ref"=>"alpha"}, []], ["charly", {}, []]]]]],
      ps.tree)
  end

  #
  # TEST 1

  class Test1 < OpenWFE::ProcessDefinition

    description "interference of the description"

    sequence do
      alpha
      bravo
    end
  end

  def test_1

    @engine.register_participant "alpha", OpenWFE::NullParticipant

    fei = @engine.launch Test1

    sleep 0.350

    ps = @engine.process_stack(fei)

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"1"}, [["description", {}, ["interference of the description"]], ["sequence", {}, [["alpha", {"ref"=>"alpha"}, []], ["bravo", {}, []]]]]],
      ps.tree)

    #
    # change process instance (charly instead of bravo)

    esequence = ps.find { |fexp| fexp.fei.expid == '0.1' }

    @engine.update_raw_expression(esequence.fei, ['charly', {}, []], 1)

    ps = @engine.process_stack(fei)

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"1"}, [["description", {}, ["interference of the description"]], ["sequence", {}, [["alpha", {"ref"=>"alpha"}, []], ["charly", {}, []]]]]],
      ps.tree)

    #
    # nuke participant charly

    #@engine.update_raw_expression(esequence.fei, nil, 1)
    @engine.update_raw_expression(esequence.fei, ["sequence", {}, [["alpha", {"ref"=>"alpha"}, []]]])

    #sleep 0.350

    ps = @engine.process_stack(fei)

    #p ps.representation

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"1"}, [["description", {}, ["interference of the description"]], ["sequence", {}, [["alpha", {"ref"=>"alpha"}, []]]]]],
      ps.tree)

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"1"}, [["description", {}, ["interference of the description"]], ["sequence", {}, [["alpha", {"ref"=>"alpha"}, []]]]]],
      @engine.process_tree(fei.wfid))
  end

  # see also test/ft_84_updateexp.rb

end
