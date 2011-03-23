
#
# testing ruote
#
# Wed Jul 29 23:25:44 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftConcurrentIteratorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_iterator

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace('done.', pdef)
  end

  def test_empty_list

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        citerator :on_val => '', :to_var => 'v' do
          echo 'x'
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace('done.', pdef)
  end

  def test_iterator

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ], trace
    assert_equal 3, @subs.sort.uniq.size
  end

  def test_iterator_cbeer

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_field => 'assets', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef, 'assets' => %w[ a b c ])

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ a/0_0_0 b/0_0_0 c/0_0_0 ], trace
    assert_equal 3, @subs.sort.uniq.size
  end

  def test_iterator_to_f

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_val => 'alice, bob, charly', :to_field => 'f' do
        participant '${f:f}'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ], trace
    assert_equal 3, @subs.sort.uniq.size
  end

  def test_iterator_with_array_param

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_val => %w[ a b c ], :to_field => 'f' do
          participant '${f:f}'
        end
        echo 'done.'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ a/0_0_0_0 b/0_0_0_0 c/0_0_0_0 done. ], trace
    assert_equal 3, @subs.sort.uniq.size
  end

  def test_iterator_with_branches_finishing_before_others

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_value => (1..2).to_a, :to_field => 'f' do
          sequence do
            participant_1
            participant_2
          end
        end
        participant_3
      end
    end

    sto = @engine.register_participant '.+', Ruote::StorageParticipant

    assert_equal 0, sto.size # just to be sure

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:participant_1)
    wait_for(:participant_1)

    assert_equal(
      { 'participant_1' => 2 },
      sto.per_participant_count)

    sto.proceed(sto.first)

    wait_for(:participant_2)
    wait_for(1)

    assert_equal(
      { 'participant_1' => 1, 'participant_2' => 1 },
      sto.per_participant_count)

    sto.proceed(sto.per_participant['participant_2'].first)

    wait_for(3)

    assert_equal 1, sto.size
    assert_equal 'participant_1', sto.first.participant_name
  end

  def test_passing_non_array_as_thing_to_iterate

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_val => { 'a' => 'A' }, :to_f => 'f' do
          p1
        end
        echo 'out'
      end
    end

    @engine.register_participant :p1 do |workitem|
      @tracer << "p1:#{workitem.fields['f'].join(':')}\n"
    end

    #noisy

    assert_trace %w[ p1:a:A out ], pdef
  end

  def test_without_to

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_value => (1..2).to_a do
        echo 'a'
      end
    end

    #noisy

    assert_trace %w[ a a ], pdef
  end

  def test_branches_att

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :branches => '2' do
        echo 'a'
      end
    end

    #noisy

    assert_trace %w[ a a ], pdef
  end

  def test_implicit_i_variable

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_val => 'alice, bob, charly' do
        participant '${v:i}:${v:ii}'
      end
    end

    register_catchall_participant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(wfid)

    trace = @tracer.to_s.split("\n").sort
    assert_equal %w[ alice:0/0_0_0 bob:1/0_0_0 charly:2/0_0_0 ], trace
    assert_equal 3, @subs.sort.uniq.size
  end

  def test_on_only

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on => 'a, b, c' do
        echo '${v:i}'
      end
    end

    #noisy

    #assert_trace(*%w[ a b c ].permutation.to_a, pdef)
      # this is not ruby 1.8.7p72 friendly

    perms = %w[ a b c ].permutation.to_a
    perms << pdef
    assert_trace(*perms)
  end

  def test_merge_type_isolate

    pdef = Ruote.process_definition do
      concurrent_iterator :on => 'a, b, c', :to_f => 'f', :merge_type => 'isolate' do
        echo '.'
      end
      bravo
    end

    @engine.register_participant :bravo do |workitem|
      stash[:mf] = workitem.fields
      nil
    end

    #noisy

    assert_trace(%w[ . . . ], pdef)

    mf = ('0'..'2').to_a.map { |k| @engine.context.stash[:mf][k]['f'] }.sort
    assert_equal %w[ a b c ], mf
  end

  def test_merge_type_stack

    pdef = Ruote.process_definition do
      concurrent_iterator :on => 'a, b', :to_f => 'f', :merge_type => 'stack' do
        echo '.'
      end
      bravo
    end

    @engine.register_participant :bravo do |workitem|
      stash[:mf] = workitem.fields
      nil
    end

    #noisy

    assert_trace(%w[ . . ], pdef)

    assert_equal(
      [["a"], ["b"]],
      @engine.context.stash[:mf]['stack'].collect { |f| f.values }.sort)
    assert_equal(
      {"on"=>"a, b", "to_f"=>"f", "merge_type"=>"stack"},
      @engine.context.stash[:mf]['stack_attributes'])
  end

  def test_cancel

    #n = 77
    n = 14

    pdef = Ruote.process_definition do
      concurrent_iterator :times => n do
        sequence do
          alpha
          bravo
        end
      end
    end

    @engine.context.stash[:a_count] = 0
    @engine.register_participant(:alpha) { |wi| stash[:a_count] += 1 }
    @engine.register_participant(:bravo, Ruote::NullParticipant)

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(2 + n * 5)
    #p "=" * 80

    assert_equal n, @engine.context.stash[:a_count]

    @engine.cancel_process(wfid)
    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end

  def test_add_branch_command

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_value => (1..2).to_a, :to_field => 'f' do
          alpha
        end
        echo '.'
      end
    end

    @engine.register_participant 'alpha' do |wi|

      @tracer << "#{workitem.fields['f']}\n"

      wi.fields['__add_branches__'] = %w[ a b ] if wi.fields['f'] == 2
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    assert_equal %w[ . 1 2 a b ], @tracer.to_a.sort
  end

  protected

  def register_catchall_participant

    @subs = []
    subs = @subs
    @engine.context.instance_eval do
      @subs = subs
    end

    @engine.register_participant '.*' do |workitem|

      @subs << workitem.fei.subid

      @tracer << [
        workitem.participant_name, workitem.fei.expid
      ].join('/') + "\n"
    end
  end
end

