
#
# testing ruote
#
# Fri May 15 09:51:28 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_process

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant
    wfid = @dashboard.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal 'my process', ps.definition_name

    assert_equal(
      {"my process"=>["0", ["define", {"my process"=>nil}, [["sequence", {}, [["set", {"var"=>"toto", "val"=>"nada"}, []], ["participant", {"ref"=>"alpha"}, []]]]]]], "toto"=>"nada"},
      ps.variables)
  end

  def test_errors

    pdef = Ruote.process_definition 'my process' do
      nada
    end

    wfid = @dashboard.launch(pdef)
    wait_for(wfid)

    errs = @dashboard.errors

    assert_equal 1, errs.size

    assert_equal wfid, errs.first.wfid

    err = @dashboard.errors(wfid)

    assert_equal 1, err.size
    assert_equal wfid, err.first.wfid

    assert_equal 1, @dashboard.errors(:count => true)
  end

  def test_current_tree

    pdef = Ruote.process_definition 'my process' do
      sequence do
        echo 'ok'
        participant :ref => :alpha
      end
    end

    alpha = @dashboard.register :alpha, Ruote::NullParticipant
    wfid = @dashboard.launch(pdef)

    wait_for('dispatched')

    ps = @dashboard.process(wfid)

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
          ["participant", {"ref"=>"alpha"}, []]]]]],
      ps.original_tree)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["participant", {"ref"=>"bravo"}, []]]]]],
      ps.current_tree)
  end

  def test_current_tree_and_re_apply

    pdef = Ruote.process_definition 'my process' do
      sequence do
        echo 'ok'
        participant :ref => :alpha
      end
    end

    alpha = @dashboard.register :alpha, Ruote::NullParticipant
    wfid = @dashboard.launch(pdef)

    wait_for('dispatched')

    ps = @dashboard.process(wfid)
    exp = ps.expressions.find { |fexp| fexp.fei.expid == '0_0_1' }

    @dashboard.re_apply(
      exp,
      :tree =>
        [ 'sequence', {}, [ [ 'alpha', {}, [] ], [ 'alpha', {}, [] ] ] ])

    wait_for('dispatched')

    ps = @dashboard.process(wfid)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["sequence", {}, [
          ["echo", {"ok"=>nil}, []],
          ["sequence", {"_triggered"=>"on_re_apply"}, [
            ["participant", {"ref"=>"alpha"}, []],
            ["alpha", {}, []]]]]]]],
      ps.current_tree)
  end

  def test_tree_when_define_rewrites_it

    pdef = Ruote.process_definition 'my process' do
      participant :ref => :alpha
      define 'sub0' do
        echo 'meh'
      end
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant
    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal(
      {"my process"=>["0", ["define", {"my process"=>nil}, [["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]], ["participant", {"ref"=>"alpha"}, []]]]], "sub0"=>["0_0", ["define", {"sub0"=>nil}, [["echo", {"meh"=>nil}, []]]]]},
      ps.variables)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["define", {"sub0"=>nil}, [
          ["echo", {"meh"=>nil}, []]]],
        ["participant", {"ref"=>"alpha"}, []]]],
      ps.current_tree)

    assert_equal(
      ["define", {"my process"=>nil}, [
        ["define", {"sub0"=>nil}, [
          ["echo", {"meh"=>nil}, []]]],
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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal %w[ main main/part part ], ps.tags.keys.sort
    assert_equal %w[ main main/part part ], ps.all_tags.keys.sort

    assert_equal 3, ps.all_tags.size
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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)
    wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal 2, ps.tags.size
    assert_equal 2, ps.all_tags['tag0'].size
  end

  def test_processes

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid0 = @dashboard.launch(pdef)
    wfid1 = @dashboard.launch(pdef)

    wait_for(:alpha)
    wait_for(:alpha)

    ps = @dashboard.processes

    assert_equal 2, ps.size
    assert_equal [ wfid0, wfid1 ].sort, ps.collect { |e| e.wfid }.sort

    assert_equal 2, alpha.size
  end

  def test_processes_and_leftovers

    n = 3

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    n.times.collect { @dashboard.launch(Ruote.define { alpha }) }

    while @dashboard.storage_participant.size < n; sleep 0.100; end
    sleep 0.100

    @dashboard.ps(@dashboard.storage_participant.first.wfid).expressions.each do |exp|
      @dashboard.storage.delete(exp.h)
    end
      # nuking all the expressions of a process instance

    assert_equal n - 1, @dashboard.processes.size
    assert_equal n,  @dashboard.storage_participant.size
      # orphan workitem left in storage

    assert_equal 1, @dashboard.leftovers.size
  end

  def test_left_overs

    [
      { '_id' => '0!f!x', 'type' => 'workitems', 'fei' => { 'wfid' => 'x' } },
      { '_id' => '0!f!y', 'type' => 'errors', 'fei' => { 'wfid' => 'y' } },
      { '_id' => '0!f!a', 'type' => 'workitems', 'fei' => { 'wfid' => 'a' } },
      { '_id' => '0!f!a', 'type' => 'expressions', 'fei' => { 'wfid' => 'a' } },
      { '_id' => '0!f!z', 'type' => 'schedules', 'fei' => { 'wfid' => 'z' },
        'at' => Ruote.time_to_utc_s(Time.now + 24 * 3600) }
    ].each do |doc|
      @dashboard.storage.put(doc)
    end

    assert_equal(
      3,
      @dashboard.leftovers.size)
    assert_equal(
      %w[ workitems errors schedules ],
      @dashboard.leftovers.collect { |lo| lo['type'] })
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

    @dashboard.register_participant :alpha do |wi, fexp|

      tracer << "a\n"

      parent = fexp.parent
      parent.update_tree
      parent.updated_tree[2][1] = [ 'charly', {}, [] ]
      parent.persist
    end

    @dashboard.register_participant :bravo do |wi, fexp|
      tracer << "b\n"
    end
    @dashboard.register_participant :charly do |wi, fexp|
      tracer << "c\n"
      stash[:tree0] = fexp.context.engine.process(fexp.fei.wfid).current_tree
    end
    @dashboard.register_participant :delta do |wi, fexp|
      tracer << "d\n"
      stash[:tree1] = fexp.context.engine.process(fexp.fei.wfid).current_tree
    end

    assert_trace %w[ a c c d ], pdef

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["sequence", {}, [
          ["alpha", {}, []],
          ["charly", {}, []],
          ["participant", {"ref"=>"charly"}, []]]],
        ["delta", {}, []]]],
      @dashboard.context.stash[:tree0])

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["sequence", {}, [
          ["alpha", {}, []],
          ["charly", {}, []],
          ["charly", {}, []]]],
        ["participant", {"ref"=>"delta"}, []]]],
      @dashboard.context.stash[:tree1])
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

    alpha = @dashboard.register :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    @dashboard.cancel_process(wfid)

    wait_for(:alpha)
    wait_for(1)

    assert_match wfid, alpha.first.fei.wfid
    assert_not_nil alpha.first.fei.subid

    assert_equal 0, @dashboard.process(wfid).errors.size
    assert_equal 4, @dashboard.process(wfid).expressions.size

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [["alpha", {}, []]]],
        ["sequence", {"on_cancel"=>"sub0"}, [["alpha", {}, []]]]]],
      @dashboard.process(wfid).original_tree)

    assert_equal(
      ["define", {"name"=>"test"}, [
        ["define", {"sub0"=>nil}, [
          ["alpha", {}, []]]],
        ["subprocess", {"_triggered"=>"on_cancel", "ref"=>"sub0"}, [
          ["define", {"sub0"=>nil}, [
            ["participant", {"ref"=>"alpha"}, []]]]]]]],
      @dashboard.process(wfid).current_tree)
  end

  def test_fexp_to_h

    pdef = Ruote.process_definition :name => 'my process' do
      participant :ref => 'alpha'
    end

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

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

    alpha = @dashboard.register_participant :alpha, Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    ps = @dashboard.process(wfid)

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

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    t0 = Time.parse(@dashboard.process(wfid).last_active)

    sp = @dashboard.storage_participant
    sp.proceed(sp.first)

    @dashboard.wait_for(:bravo)

    t1 = Time.parse(@dashboard.process(wfid).last_active)

    assert t1 > t0
  end

  def test_position

    pdef = Ruote.define do
      alpha :task => 'clean car'
    end

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(:alpha)

    assert_equal(
      [ [ 'alpha', { 'task' => 'clean car' } ] ],
      @dashboard.process(wfid).position.collect { |pos| pos[1..-1] })

    # #position leverages #workitems

    assert_equal(
      [ [ wfid, 'alpha' ] ],
      @dashboard.process(wfid).workitems.collect { |wi|
        [ wi.fei.wfid, wi.participant_name ]
      })
  end

  def test_position_when_error

    pdef = Ruote.define do
      participant
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal 1, @dashboard.process(wfid).errors.size

    assert_equal(
      [ [ nil,
          { 'error' => '#<ArgumentError: no participant name specified>' } ] ],
      @dashboard.process(wfid).position.collect { |pos| pos[1..-1] })
  end

  def test_ps_with_stored_workitems

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.define { alpha })
    @dashboard.wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.stored_workitems.size
    assert_equal Ruote::Workitem, ps.stored_workitems.first.class
  end

  def test_ps_without_stored_workitems

    @dashboard.register_participant '.+', Ruote::NullParticipant

    wfid = @dashboard.launch(Ruote.define { alpha })
    @dashboard.wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal 0, ps.stored_workitems.size
  end

  def test_schedules

    @dashboard.register_participant '.+', Ruote::NullParticipant

    wfid = @dashboard.launch(Ruote.define { alpha :timeout => '2d' })
    @dashboard.wait_for(:alpha)

    assert_equal 1, @dashboard.schedules.size
    assert_equal 1, @dashboard.schedules(:count => true)
  end

  def test_processes_and_schedules

    @dashboard.register_participant '.+', Ruote::NullParticipant

    wfid = @dashboard.launch(Ruote.define { alpha :timeout => '2d' })
    @dashboard.wait_for(:alpha)

    ps = @dashboard.process(wfid)

    assert_equal 1, ps.schedules.size
    assert_match /^0_0![a-f0-9]+!#{wfid}$/, ps.schedules.first['target'].sid
  end

  def test_ps_pagination

    n = 7

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfids = (1..n).collect { |i|
      @dashboard.launch(Ruote.define { alpha })
    }.sort

    while @dashboard.storage_participant.size < n; sleep 0.140; end

    assert_equal wfids, @dashboard.process_wfids

    assert_equal(
      wfids,
      @dashboard.processes.collect { |ps| ps.wfid })

    assert_equal(
      wfids,
      @dashboard.processes(:test => :garbage).collect { |ps| ps.wfid })
        # prompted by
        # http://groups.google.com/group/openwferu-users/browse_thread/thread/ee493bdf8d8cdb37

    assert_equal(
      wfids[0, 3],
      @dashboard.processes(:limit => 3).collect { |ps| ps.wfid })

    assert_equal(
      wfids[3, 3],
      @dashboard.processes(:skip => 3, :limit => 3).collect { |ps| ps.wfid })

    #puts "==="
    #wfids.each { |wfid| puts wfid }
    #puts "---"
    #@dashboard.processes(:limit => 3, :descending => false).collect { |ps| ps.wfid }.each { |wfid| puts wfid }
    #puts "---"
    #@dashboard.processes(:limit => 3, :descending => true).collect { |ps| ps.wfid }.each { |wfid| puts wfid }

    assert_equal(
      wfids.reverse[0, 3],
      @dashboard.processes(
        :limit => 3, :descending => true
      ).collect { |ps| ps.wfid })

    assert_equal(
      n,
      @dashboard.processes(:count => true))
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

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(4)

    #assert_equal 1, @dashboard.processes.size
    assert_equal [ wfid ], @dashboard.processes.collect { |ps| ps.wfid }
  end

  def test_ps

    @dashboard.register 'alpha', Ruote::NullParticipant

    wfid = nil

    2.times { wfid = @dashboard.launch(Ruote.define { alpha }) }

    @dashboard.wait_for(4)

    assert_equal 2, @dashboard.ps.size
    assert_equal wfid, @dashboard.ps(wfid).wfid
  end

  def test_definition_name

    pdef = Ruote.process_definition :name => 'invictus' do
      alpha
    end

    alpha = @dashboard.register_participant :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)

    assert_equal 'invictus', @dashboard.process(wfid).definition_name

    exp = @dashboard.process(wfid).expressions.first
    @dashboard.storage.delete(exp.h)

    assert_nil @dashboard.process(wfid).definition_name
    assert_nil @dashboard.process(wfid).definition_revision
  end

  def test_leaves

    pdef = Ruote.define do
      concurrence do
        alpha
        wait '1w'
      end
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)
    wait_for(1)

    leaves = @dashboard.process(wfid).leaves

    assert_equal(
      [ "0_0_0:Ruote::Exp::ParticipantExpression:",
        "0_0_1:Ruote::Exp::WaitExpression:" ],
      leaves.collect { |fexp|
        [ fexp.fei.expid,
          fexp.class.to_s,
          fexp.error ? fexp.error.message : '' ].join(':')
      })
  end

  def test_leaves_when_errors

    pdef = Ruote.define do
      concurrence do
        wait '1w'
        participant
        alpha
      end
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef)

    wait_for(:alpha)
    wait_for(1)

    leaves = @dashboard.process(wfid).leaves

    assert_equal(
      [ "0_0_0:Ruote::Exp::WaitExpression:",
        "0_0_1:Ruote::Exp::ParticipantExpression:#<ArgumentError: no participant name specified>",
        "0_0_2:Ruote::Exp::ParticipantExpression:" ],
      leaves.collect { |fexp|
        [ fexp.fei.expid,
          fexp.class.to_s,
          fexp.error ? fexp.error.message : '' ].join(':')
      })
  end

  def test_root_workitem

    pdef = Ruote.define do
      alpha
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant

    wfid = @dashboard.launch(pdef, 'small' => 'town')

    wait_for(:alpha)

    wi = @dashboard.process(wfid).root_workitem

    assert_equal 'town', wi.fields['small']
  end

  def test_to_h

    @dashboard.register_participant :alpha, Ruote::StorageParticipant

    pdef = Ruote.define do
      concurrence do
        alpha
        wait '1d'
        nada
      end
    end

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(7)

    assert_equal Hash, @dashboard.ps(wfid).to_h.class
  end
end

