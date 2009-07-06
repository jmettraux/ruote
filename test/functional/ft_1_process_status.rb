
#
# Testing Ruote (OpenWFEru)
#
# Fri May 15 09:51:28 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_ps

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 'my process', ps.definition_name
    assert_equal nil, ps.definition_revision
    assert_equal({}, ps.variables)
    assert_not_nil ps.launched_time
  end

  def test_variables

    pdef = Ruote.process_definition 'my process' do
      sequence do
        set :var => 'toto', :val => 'nada'
        participant :ref => 'alpha'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 'my process', ps.definition_name
    assert_equal({ 'toto' => 'nada' }, ps.variables)
  end

  def test_tree

    pdef = Ruote.process_definition 'my process' do
      sequence do
        echo 'ok'
        participant :ref => :alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

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

  def test_tree_when_define_rewrites_it

    pdef = Ruote.process_definition 'my process' do
      participant :ref => :alpha
      define 'sub0' do
        echo 'meh'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

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

  def test_sub_processes

    pdef = Ruote.process_definition do
      define 'sub0' do
        alpha
      end
      sequence do
        sub0
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal "#{wfid}_0", alpha.first.fei.wfid

    ps = @engine.process(wfid)

    #ps.expressions.each { |e| puts e.fei.to_s }

    assert_equal 5, ps.expressions.size

    assert_equal(
      [ wfid, "#{wfid}_0" ],
      ps.expressions.collect { |e| e.fei.wfid }.sort.uniq)
  end

  def test_all_variables

    pdef = Ruote.process_definition do
      define 'sub0' do
        sequence do
          set :var => 'v1', :val => 1
          alpha
        end
      end
      sequence do
        set :var => 'v0', :val => 0
        sub0
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal(0, ps.variables['v0'])
    assert_equal(nil, ps.variables['v1'])

    #p ps.all_variables
    assert_equal(2, ps.all_variables.size)

    h = ps.all_variables.values.inject({}) { |h, vh| h.merge!(vh) }

    assert_equal(0, h['v0'])
    assert_equal(1, h['v1'])
  end

  def test_tags

    pdef = Ruote.process_definition do
      sequence :tag => 'main' do
        alpha :tag => 'part'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 2, ps.tags.size

    assert_equal 2, ps.all_tags.size
    assert_kind_of Array, ps.all_tags['main']
    assert_equal 1, ps.all_tags['main'].size
  end

  def test_all_tags

    pdef = Ruote.process_definition do
      define 'sub0' do
        sequence :tag => 'tag0' do
          alpha
        end
      end
      sequence :tag => 'tag0' do
        sub0
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 1, ps.tags.size
    assert_equal 2, ps.all_tags['tag0'].size
  end

  def test_processes

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant

    wfid0 = @engine.launch(pdef)
    wfid1 = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    ps = @engine.processes

    assert_equal 2, ps.size
    assert_equal [ wfid0, wfid1 ], ps.collect { |e| e.wfid }.sort

    assert_equal 2, alpha.size
  end
end

