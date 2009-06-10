
#
# Testing Ruote (OpenWFEru)
#
# Fri May 15 09:51:28 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_process_status

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpja)

    ps = @engine.process_status(wfid)

    assert_equal 'my process', ps.definition_name
    assert_equal nil, ps.definition_revision
    assert_equal({}, ps.variables)
    assert_not_nil ps.launched_time
  end

  def test_process_status_variables

    pdef = Ruote.process_definition 'my process' do
      sequence do
        set :var => 'toto', :val => 'nada'
        participant :ref => 'alpha'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpha)

    ps = @engine.process_status(wfid)

    assert_equal 'my process', ps.definition_name
    assert_equal({ 'toto' => 'nada' }, ps.variables)
  end

  def test_process_status_tree

    pdef = Ruote.process_definition 'my process' do
      sequence do
        echo 'ok'
        participant :ref => :alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process_status(wfid)

    assert_equal(
      ["sequence", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>:alpha}, []]]]]],
      ps.current_tree)

    assert_equal(
      ["sequence", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>:alpha}, []]]]]],
      ps.original_tree)

    #
    # tinkering with trees ...

    e = ps.expressions.find { |e| e.fei.expid == '0_0_1' }

    e.tree = [ 'participant', { 'ref' => :bravo }, [] ]

    assert_equal(
      ["sequence", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>:bravo}, []]]]]],
      ps.current_tree)

    assert_equal(
      ["sequence", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>:alpha}, []]]]]],
      ps.original_tree)
  end

  def test_process_status_tree_when_define_rewrites_it

    pdef = Ruote.process_definition 'my process' do
      participant :ref => :alpha
      define 'sub0' do
        echo 'meh'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process_status(wfid)

    assert_equal(
      {"sub0" => [
        "0_0", ["sequence", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]]]},
      ps.variables)

    assert_equal(
      ["sequence", {"my process"=>nil}, [
        ["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]],
        ["participant", {"ref"=>:alpha}, []]]],
      ps.current_tree)

    assert_equal(
      ["sequence", {"my process"=>nil}, [
        ["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]],
        ["participant", {"ref"=>:alpha}, []]]],
      ps.original_tree)
  end
end

