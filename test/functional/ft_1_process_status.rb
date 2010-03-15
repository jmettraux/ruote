
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_ps

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 'my process', ps.definition_name
    assert_equal nil, ps.definition_revision
    assert_not_nil ps.launched_time

    assert_equal(
      {"my process"=>["0", ["define", {"name"=>"my process"}, [["participant", {"ref"=>"alpha"}, []]]]]},
      ps.variables)

    # checking process_status.to_h

    h = ps.to_h
    #p h

    assert_equal wfid, h['wfid']
    assert_equal 2, h['expressions'].size
    assert_equal 'my process', h['definition_name']

    assert_equal Time, Time.parse(h['launched_time']).class

    assert_equal(
      ["define", {"name"=>"my process"}, [["participant", {"ref"=>"alpha"}, []]]],
      h['original_tree'])

    assert_equal(
      ["define", {"name"=>"my process"}, [["participant", {"ref"=>"alpha"}, []]]],
      h['current_tree'])

    assert_equal(
      {"my process"=>["0", ["define", {"name"=>"my process"}, [["participant", {"ref"=>"alpha"}, []]]]]},
      h['variables'])
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

    assert_equal(
      {"my process"=>["0", ["define", {"my process"=>nil}, [["sequence", {}, [["set", {"var"=>"toto", "val"=>"nada"}, []], ["participant", {"ref"=>"alpha"}, []]]]]]], "toto"=>"nada"},
      ps.variables)
  end

  def test_errors

    pdef = Ruote.process_definition 'my process' do
      nada
    end

    wfid = @engine.launch( pdef )
    wait_for( wfid )

    errs = @engine.errors

    assert_equal 1, errs.size

    assert_equal wfid, errs.first['fei']['wfid']

    err = @engine.errors( wfid )

    assert_equal 1, err.size
    assert_equal wfid, err.first['fei']['wfid']
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
      ["define", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>"alpha"}, []]]]]],
      ps.current_tree)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>"alpha"}, []]]]]],
      ps.original_tree)

    #
    # tinkering with trees ...

    e = ps.expressions.find { |e| e.fei.expid == '0_0_1' }

    e.update_tree([ 'participant', { 'ref' => 'bravo' }, [] ])

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>"bravo"}, []]]]]],
      ps.current_tree)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>"alpha"}, []]]]]],
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
      {"my process"=>["0", ["define", {"my process"=>nil}, [["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]], ["participant", {"ref"=>"alpha"}, []]]]], "sub0"=>["0_0", ["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]]]},
      ps.variables)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]],
        ["participant", {"ref"=>"alpha"}, []]]],
      ps.current_tree)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]],
        ["participant", {"ref"=>"alpha"}, []]]],
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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal wfid, alpha.first.fei.wfid
    assert_not_nil alpha.first.fei.sub_wfid

    ps = @engine.process(wfid)

    #ps.expressions.each { |e| puts e.fei.to_s }

    assert_equal 5, ps.expressions.size

    wfids = ps.expressions.collect { |e|
      [ e.fei.wfid, e.fei.sub_wfid ].join('|')
    }.sort.uniq

    assert_equal 2, wfids.size
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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

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

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid0 = @engine.launch(pdef)
    wfid1 = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    ps = @engine.processes

    assert_equal 2, ps.size
    assert_equal [ wfid0, wfid1 ].sort, ps.collect { |e| e.wfid }.sort

    assert_equal 2, alpha.size
  end

  def test_tree_rewrite

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        alpha
        bravo
        charly
      end
      delta
    end

    tree0 = nil
    tree1 = nil

    @engine.register_participant :alpha do |wi, fexp|

      @tracer << "a\n"

      parent = fexp.parent
      parent.update_tree
      parent.updated_tree[2][1] = [ 'charly', {}, [] ]
      parent.persist
    end

    @engine.register_participant :bravo do |wi, fexp|
      @tracer << "b\n"
    end
    @engine.register_participant :charly do |wi, fexp|
      @tracer << "c\n"
      tree0 = fexp.context.engine.process(fexp.fei.wfid).current_tree
    end
    @engine.register_participant :delta do |wi, fexp|
      @tracer << "d\n"
      tree1 = fexp.context.engine.process(fexp.fei.wfid).current_tree
    end

    #noisy

    assert_trace %w[ a c c d ], pdef

    assert_equal(
      ["define", {"name"=>"test"}, [["sequence", {}, [["alpha", {}, []], ["charly", {}, []], ["participant", {"ref"=>"charly"}, []]]], ["delta", {}, []]]],
      tree0)

    assert_equal(
      ["define", {"name"=>"test"}, [["sequence", {}, [["alpha", {}, []], ["charly", {}, []], ["charly", {}, []]]], ["participant", {"ref"=>"delta"}, []]]],
      tree1)
  end

  def test_when_on_cancel_subprocess

    pdef = Ruote.process_definition :name => 'test' do
      sequence :on_cancel => 'sub0' do
        alpha
      end
      define 'sub0' do
        alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @engine.cancel_process(wfid)

    wait_for(:alpha)

    assert_match wfid, alpha.first.fei.wfid
    assert_not_nil alpha.first.fei.sub_wfid

    assert_equal 0, @engine.process(wfid).errors.size
    assert_equal 4, @engine.process(wfid).expressions.size

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [["alpha", {}, []]]],
        ["sequence", {"on_cancel"=>"sub0"}, [["alpha", {}, []]]]]],
      @engine.process(wfid).original_tree)

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [
          ["participant", {"ref"=>"alpha"}, []]]],
        ["sequence", {"on_cancel"=>"sub0", "_triggered"=>"on_cancel"}, [
          ["alpha", {}, []]]]]],
      @engine.process(wfid).current_tree)
  end

  def test_fexp_to_h

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

    h = ps.expressions.find { |hf|
      hf.is_a?(Ruote::Exp::ParticipantExpression)
    }.to_h

    assert_equal 'participant', h['name']
    assert_equal 'alpha', h['participant_name']
    assert_equal ["participant", {"ref"=>"alpha"}, []], h['original_tree']
  end

  def test_to_dot

    pdef = Ruote.process_definition :name => 'my process' do
      concurrence do
        participant :ref => 'alpha'
        participant :ref => 'bravo'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant.new

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

    #puts
    #puts ps.to_dot

    dot = ps.to_dot
    dot = dot.gsub(wfid, 'wfid').strip

    assert_equal(
      %{
digraph "process wfid wfid" {
"0!!wfid" [ label="wfid  0 define" ];
"0!!wfid" -> "0_0!!wfid";
"0_0!!wfid" [ label="wfid  0_0 concurrence" ];
"0_0!!wfid" -> "0!!wfid";
"0_0!!wfid" -> "0_0_0!!wfid";
"0_0!!wfid" -> "0_0_1!!wfid";
"0_0_0!!wfid" [ label="wfid  0_0_0 participant" ];
"0_0_0!!wfid" -> "0_0!!wfid";
"0_0_1!!wfid" [ label="wfid  0_0_1 participant" ];
"0_0_1!!wfid" -> "0_0!!wfid";
"err_0_0_1!!wfid" [ label = "error : #<ArgumentError: no participant named 'bravo'>" ];
"err_0_0_1!!wfid" -> "0_0_1!!wfid" [ style = "dotted" ];
}
      }.strip,
      dot)
  end
end

