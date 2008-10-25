
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Mar  9 20:43:02 JST 2008
#

require 'flowtestbase'

require 'openwfe/def'
require 'openwfe/participants/storeparticipants'
require 'openwfe/storage/yamlcustom'


#class Array
#  alias :old_inspect :inspect
#  def inspect
#    "#{self.object_id}:#{old_inspect}"
#  end
#end


class FlowTest84 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
     sequence do
       set :var => "v0", :val => "val0"
       store_p
     end
  end

  def test_0

    #sp = @engine.register_participant("store_p", OpenWFE::YamlParticipant)
    sp = @engine.register_participant("store_p", OpenWFE::HashParticipant)

    fei = launch TestDefinition0

    sleep 0.350

    #s = @engine.process_stack fei, true
    s = @engine.process_stack(fei)

    env = s.find { |fexp| fexp.is_a?(OpenWFE::Environment) }
    par = s.find { |fexp| fexp.is_a?(OpenWFE::ParticipantExpression) }

    #
    # testing update on env

    assert_equal "val0", @engine.lookup_variable("v0", fei)

    @engine.update_expression_data(
      env.fei, { "v0" => "val0b", "v1" => "val1" })

    assert_equal "val0b", @engine.lookup_variable("v0", fei)
    assert_equal "val1", @engine.lookup_variable("v1", fei)

    #
    # testing update on participant expression

    assert [ 1, 2 ], par.applied_workitem.attributes

    @engine.update_expression_data par.fei, { 'f0' => 'val0' }

    s = @engine.process_stack fei
    par = s.find { |fexp| fexp.is_a?(OpenWFE::ParticipantExpression) }

    assert_equal 'val0', par.applied_workitem.attributes['f0']

    @engine.cancel_process fei.wfid

    sleep 0.350
  end

  #
  # TEST 1

  class TestDefinition1 < OpenWFE::ProcessDefinition
   sequence do
     participant 'alpha'
     participant 'bravo'
   end
  end

  def test_1

    %w{ alpha bravo charly }.each do |pname|
      @engine.register_participant pname, OpenWFE::HashParticipant
    end

    fei = launch(TestDefinition1)

    sleep 0.350

    assert 1, @engine.get_participant('alpha').size
    assert 0, @engine.get_participant('bravo').size
    assert 0, @engine.get_participant('charly').size

    ps = @engine.process_stack(fei.wfid)
    #puts ps.collect { |fexp| fexp.to_yaml }.join("\n")

    esequence = ps.find { |fexp| fexp.fei.expid == '0.0' }
    esequence.raw_representation = [
      'sequence', {}, [
        [ 'alpha', {}, [] ],
        [ 'charly', {}, [] ]
      ]
    ]

    @engine.update_expression(esequence)

    wi = @engine.get_participant('alpha').first_workitem
    @engine.get_participant('alpha').forward(wi)

    sleep 0.350

    assert 0, @engine.get_participant('alpha').size
    assert 0, @engine.get_participant('bravo').size
    assert 1, @engine.get_participant('charly').size

    @engine.cancel_process fei.wfid

    sleep 0.350
  end

  #
  # TEST 2

  class TestDefinition2 < OpenWFE::ProcessDefinition
     sequence do
       participant "alpha"
       participant "alpha"
       participant "charly"
     end
  end

  def test_2

    #log_level_to_debug

    %w{ alpha bravo charly }.each do |pname|
      @engine.register_participant(pname, OpenWFE::HashParticipant)
    end

    fei = launch(TestDefinition2)

    sleep 0.350

    #
    # in the beginning...

    #ps = @engine.process_stack fei.wfid, true
    ps = @engine.process_stack(fei.wfid)

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"2"}, [["sequence", {}, [["participant", {}, ["alpha"]], ["participant", {}, ["alpha"]], ["participant", {}, ["charly"]]]]]],
      ps.tree)

    esequence = ps.find { |fexp| fexp.fei.expid == '0.0' }

    # update happens here

    @engine.update_raw_expression(esequence.fei, [ "bravo", {}, [] ], 1)

    #ps = @engine.process_stack(fei.wfid, true)
    ps = @engine.process_stack(fei.wfid)

    #p ps.representation

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"2"}, [["sequence", {}, [["participant", {}, ["alpha"]], ["bravo", {}, []], ["participant", {}, ["charly"]]]]]],
      ps.tree)

    wi = @engine.get_participant("alpha").first_workitem
    @engine.get_participant("alpha").forward(wi)

    sleep 0.350

    wi = @engine.get_participant("bravo").first_workitem
    @engine.get_participant("bravo").forward(wi)

    sleep 0.350

    ps = @engine.process_stack(fei.wfid)

    #puts
    #ps.each do |fexp|
    #  puts "== #{fexp.fei.to_short_s}"
    #  p [ fexp.raw_representation, fexp.raw_rep_updated ]
    #end
    #puts

    assert_equal(
      ["process-definition", {"name"=>"Test", "revision"=>"2"}, [["sequence", {}, [["participant", {}, ["alpha"]], ["bravo", {"ref"=>"bravo"}, []], ["participant", {}, ["charly"]]]]]],
      ps.tree)

    # just to be sure

    assert_equal 0, ps.find_all { |fexp| fexp.fei.expid == '0.0.1' }.size
      # making sure the 2nd participant is over

    #p ps.representation

    pstatus = @engine.process_status(fei.wfid)
    #p pstatus.current_tree
    #p pstatus.initial_tree

    assert_not_equal(pstatus.current_tree, pstatus.initial_tree)

    #@engine.cancel_process fei
    #sleep 0.350

    purge_engine
  end

end

