
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_process

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 'my process', ps.definition_name
    assert_equal nil, ps.definition_revision
    assert_not_nil ps.launched_time

    assert_equal(
      {"my process"=>["0", ["define", {"name"=>"my process"}, [["participant", {"ref"=>"alpha"}, []]]]]},
      ps.variables)
  end

  def test_variables

    pdef = Ruote.process_definition 'my process' do
      sequence do
        set :var => 'toto', :val => 'nada'
        participant :ref => 'alpha'
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant
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

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    errs = @engine.errors

    assert_equal 1, errs.size

    assert_equal wfid, errs.first.wfid

    err = @engine.errors(wfid)

    assert_equal 1, err.size
    assert_equal wfid, err.first.wfid

    assert_equal 1, @engine.errors(:count => true)
  end

  def test_tree

    pdef = Ruote.process_definition 'my process' do
      sequence do
        echo 'ok'
        participant :ref => :alpha
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant
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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant
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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal %w[ main part ], ps.tags.keys.sort

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid0 = @engine.launch(pdef)
    wfid1 = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    ps = @engine.processes

    assert_equal 2, ps.size
    assert_equal [ wfid0, wfid1 ].sort, ps.collect { |e| e.wfid }.sort

    assert_equal 2, alpha.size
  end

  def test_processes_and_orphans

    n = 3

    @engine.register_participant :alpha, Ruote::StorageParticipant

    wfids = n.times.collect { @engine.launch(Ruote.define { alpha }) }

    n.times { @engine.wait_for(:alpha) }
    @engine.wait_for(1)

    @engine.processes.first.expressions.each do |exp|
      @engine.storage.delete(exp.h)
    end
      # nuking all the expressions of a process instance

    assert_equal n - 1, @engine.processes.size
    assert_equal n,  @engine.storage_participant.size
      # orphan workitem left in storage
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
      stash[:tree0] = fexp.context.engine.process(fexp.fei.wfid).current_tree
    end
    @engine.register_participant :delta do |wi, fexp|
      @tracer << "d\n"
      stash[:tree1] = fexp.context.engine.process(fexp.fei.wfid).current_tree
    end

    #noisy

    assert_trace %w[ a c c d ], pdef

    assert_equal(
      ["define", {"name"=>"test"}, [["sequence", {}, [["alpha", {}, []], ["charly", {}, []], ["participant", {"ref"=>"charly"}, []]]], ["delta", {}, []]]],
      @engine.context.stash[:tree0])

    assert_equal(
      ["define", {"name"=>"test"}, [["sequence", {}, [["alpha", {}, []], ["charly", {}, []], ["charly", {}, []]]], ["participant", {"ref"=>"delta"}, []]]],
      @engine.context.stash[:tree1])
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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    @engine.cancel_process(wfid)

    wait_for(:alpha)
    wait_for(1)

    assert_match wfid, alpha.first.fei.wfid
    assert_not_nil alpha.first.fei.subid

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

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

    alpha = @engine.register_participant :alpha, Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    ps = @engine.process(wfid)

    #puts
    #puts ps.to_dot

    dot = ps.to_dot

    dot = dot.gsub(wfid, 'wfid')
    dot = dot.gsub(/![^!]+!/, '!!')
    dot = dot.gsub(/wfid [^ ]+ /, 'wfid ')
    dot = dot.strip

    assert_equal(
      %{
digraph "process wfid {
"0!!wfid" [ label="wfid 0 define" ];
"0!!wfid" -> "0_0!!wfid";
"0_0!!wfid" [ label="wfid 0_0 concurrence" ];
"0_0!!wfid" -> "0!!wfid";
"0_0!!wfid" -> "0_0_0!!wfid";
"0_0!!wfid" -> "0_0_1!!wfid";
"0_0_0!!wfid" [ label="wfid 0_0_0 participant" ];
"0_0_0!!wfid" -> "0_0!!wfid";
"0_0_1!!wfid" [ label="wfid 0_0_1 participant" ];
"0_0_1!!wfid" -> "0_0!!wfid";
"err_0_0_1!!wfid" [ label = "error : #<ArgumentError: no participant named 'bravo'>" ];
"err_0_0_1!!wfid" -> "0_0_1!!wfid" [ style = "dotted" ];
}
      }.strip,
      dot)
  end

  def test_last_active

    pdef = Ruote.define do
      alpha
      bravo
    end

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    t0 = Time.parse(@engine.process(wfid).last_active)

    sp = @engine.storage_participant
    sp.reply(sp.first)

    @engine.wait_for(:bravo)

    t1 = Time.parse(@engine.process(wfid).last_active)

    assert t1 > t0
  end

  def test_position

    pdef = Ruote.define do
      alpha :task => 'clean car'
    end

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfid = @engine.launch(pdef)
    @engine.wait_for(:alpha)

    assert_equal(
      [ [ 'alpha', { 'task' => 'clean car' } ] ],
      @engine.process(wfid).position.collect { |pos| pos[1..-1] })

    # #position leverages #workitems

    assert_equal(
      [ [ wfid, 'alpha' ] ],
      @engine.process(wfid).workitems.collect { |wi|
        [ wi.fei.wfid, wi.participant_name ]
      })
  end

  def test_position_when_error

    pdef = Ruote.define do
      participant
    end

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal 1, @engine.process(wfid).errors.size

    assert_equal(
      [ [ nil,
          { 'error' => '#<ArgumentError: no participant name specified>' } ] ],
      @engine.process(wfid).position.collect { |pos| pos[1..-1] })
  end

  def test_ps_with_stored_workitems

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfid = @engine.launch(Ruote.define { alpha })
    @engine.wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 1, ps.stored_workitems.size
    assert_equal Ruote::Workitem, ps.stored_workitems.first.class
  end

  def test_ps_without_stored_workitems

    @engine.register_participant '.+', Ruote::NullParticipant

    wfid = @engine.launch(Ruote.define { alpha })
    @engine.wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 0, ps.stored_workitems.size
  end

  def test_schedules

    @engine.register_participant '.+', Ruote::NullParticipant

    wfid = @engine.launch(Ruote.define { alpha :timeout => '2d' })
    @engine.wait_for(:alpha)

    assert_equal 1, @engine.schedules.size
    assert_equal 1, @engine.schedules(:count => true)
  end

  def test_ps_and_schedules

    @engine.register_participant '.+', Ruote::NullParticipant

    #noisy

    wfid = @engine.launch(Ruote.define { alpha :timeout => '2d' })
    @engine.wait_for(:alpha)

    ps = @engine.process(wfid)

    assert_equal 1, ps.schedules.size
    assert_equal "0_0!!#{wfid}", ps.schedules.first['target'].sid
  end

  def test_ps_pagination

    n = 7

    @engine.register_participant '.+', Ruote::StorageParticipant

    wfids = (1..n).collect { |i|
      @engine.launch(Ruote.define { alpha })
    }.sort

    while @engine.storage_participant.size < n; sleep 0.140; end

    assert_equal wfids, @engine.process_wfids

    assert_equal(
      wfids,
      @engine.processes.collect { |ps| ps.wfid })

    assert_equal(
      wfids,
      @engine.processes(:test => :garbage).collect { |ps| ps.wfid })
        # prompted by
        # http://groups.google.com/group/openwferu-users/browse_thread/thread/ee493bdf8d8cdb37

    assert_equal(
      wfids[0, 3],
      @engine.processes(:limit => 3).collect { |ps| ps.wfid })

    assert_equal(
      wfids[3, 3],
      @engine.processes(:skip => 3, :limit => 3).collect { |ps| ps.wfid })

    #puts "==="
    #wfids.each { |wfid| puts wfid }
    #puts "---"
    #@engine.processes(:limit => 3, :descending => false).collect { |ps| ps.wfid }.each { |wfid| puts wfid }
    #puts "---"
    #@engine.processes(:limit => 3, :descending => true).collect { |ps| ps.wfid }.each { |wfid| puts wfid }

    assert_equal(
      wfids.reverse[0, 3],
      @engine.processes(
        :limit => 3, :descending => true
      ).collect { |ps| ps.wfid })

    assert_equal(
      n,
      @engine.processes(:count => true))
  end

  # Issue identified by David Goodlad :
  #
  # http://gist.github.com/600451
  #
  def test_ps_and_schedules

    pdef = Ruote.define do
      concurrence do
        wait '4h'
        wait '2h'
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    @engine.wait_for(4)

    #assert_equal 1, @engine.processes.size
    assert_equal [ wfid ], @engine.processes.collect { |ps| ps.wfid }
  end

  def test_ps

    @engine.register 'alpha', Ruote::NullParticipant

    wfid = nil

    2.times { wfid = @engine.launch(Ruote.define { alpha }) }

    @engine.wait_for(4)

    assert_equal 2, @engine.ps.size
    assert_equal wfid, @engine.ps(wfid).wfid
  end

  def test_definition_name

    pdef = Ruote.process_definition :name => 'invictus' do
      alpha
    end

    #noisy

    alpha = @engine.register_participant :alpha, Ruote::NullParticipant

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 'invictus', @engine.process(wfid).definition_name

    exp = @engine.process(wfid).expressions.first
    @engine.storage.delete(exp.h)

    assert_nil @engine.process(wfid).definition_name
    assert_nil @engine.process(wfid).definition_revision
  end
end

