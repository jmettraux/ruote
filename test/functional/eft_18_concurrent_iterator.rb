
#
# testing ruote
#
# Wed Jul 29 23:25:44 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'
require 'ruote/part/null_participant'


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

    assert_trace(pdef, 'done.')
  end

  def test_empty_list

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        concurrent_iterator :on_val => '', :to_var => 'v' do
          echo 'x'
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')
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

    p1 = @engine.register_participant :participant_1, Ruote::HashParticipant.new
    p2 = @engine.register_participant :participant_2, Ruote::HashParticipant.new
    p3 = @engine.register_participant :participant_3, Ruote::HashParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:participant_1)

    assert_equal 0, p2.size
    assert_equal 0, p3.size

    p1.reply(p1.first)

    wait_for(:participant_2)

    assert_equal 1, p2.size
    assert_equal 0, p3.size

    p2.reply(p2.first)

    wait_for(3)

    assert_equal 0, p3.size
    assert_equal 1, p1.size
    assert_equal 0, p2.size
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

    assert_trace pdef, %w[ p1:a:A out ]
  end

  def test_without_to

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :on_value => (1..2).to_a do
        echo 'a'
      end
    end

    #noisy

    assert_trace pdef, %w[ a a ]
  end

  def test_branches_att

    pdef = Ruote.process_definition :name => 'test' do
      concurrent_iterator :branches => '2' do
        echo 'a'
      end
    end

    #noisy

    assert_trace pdef, %w[ a a ]
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

    assert_trace pdef, %w[ a b c ]
  end

  def test_merge_type_isolate

    pdef = Ruote.process_definition do
      concurrent_iterator :on => 'a, b, c', :to_f => 'f', :merge_type => 'isolate' do
        echo '.'
      end
      bravo
    end

    merged_fields = nil

    @engine.register_participant :bravo do |workitem|
      merged_fields = workitem.fields
      nil
    end

    #noisy

    assert_trace(
      pdef, %w{ . . . })
    assert_equal(
      {"0" => { "f" => "a" },
       "1" => { "f" => "b" },
       "2" => { "f" => "c" },
       "params" => { "ref" => "bravo" }},
      merged_fields)
  end

  def test_cancel

    n = 77

    pdef = Ruote.process_definition do
      concurrent_iterator :times => n do
        sequence do
          alpha
          bravo
        end
      end
    end

    a_count = 0
    @engine.register_participant(:alpha) { |wi| a_count += 1 }
    @engine.register_participant(:bravo, Ruote::NullParticipant)

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(2 + n * 5)
    #p "=" * 80

    assert_equal n, a_count

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

    @engine.register_participant 'alpha' do |workitem|

      @tracer << "#{workitem.fields['f']}\n"

      workitem.fields['__add_branches__'] = %w[ a b ] \
        if workitem.fields['f'] == 2
    end

    #noisy

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    assert_equal %w[ . 1 2 a b ], @tracer.to_a.sort
  end

  protected

  def register_catchall_participant

    @subs = []

    @engine.register_participant '.*' do |workitem|

      @subs << workitem.fei.sub_wfid

      @tracer << [
        workitem.participant_name, workitem.fei.expid
      ].join('/') + "\n"
    end
  end
end

