
#
# testing ruote
#
# Mon Jun 29 09:35:48 JST 2009
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class EftIteratorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_iterator

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        end
        echo 'done.'
      end
    end

    #noisy

    assert_trace('done.', pdef)
  end

  class TraceParticipant
    include Ruote::LocalParticipant
    def consume(wi)
      context.tracer << "#{wi.participant_name}/#{wi.fei.expid}\n"
      reply(wi)
    end
  end

  def test_on_val

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    @dashboard.register_participant '.*', TraceParticipant

    #noisy

    assert_trace(%w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ], pdef)
  end

  def test_on__list

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    @dashboard.register_participant '.*', TraceParticipant

    assert_trace(%w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ], pdef)
  end

  def test_on_f

    pdef = Ruote.process_definition :name => 'test' do
      set :f => 'people', :val => %w[ alice bob charly ]
      iterator :on_f => 'people', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    @dashboard.register_participant '.*', TraceParticipant

    assert_trace(%w[ alice/0_1_0 bob/0_1_0 charly/0_1_0 ], pdef)
  end

  def test_on_nested_f

    pdef = Ruote.process_definition :name => 'test' do
      set 'f:data' => {}
      set 'f:data.people' => %w[ alice bob charly ]
      iterator :on_f => 'data.people', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    @dashboard.register_participant '.*', TraceParticipant

    assert_trace(%w[ alice/0_2_0 bob/0_2_0 charly/0_2_0 ], pdef)
  end

  def test_to_f

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_field => 'f' do
        participant '${f:f}'
      end
    end

    @dashboard.register_participant '.*' do |workitem|
      tracer << "#{workitem.fields['f']}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(%w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ], pdef)
  end

  def test_to

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'a, b', :to => 'x' do
        echo '${f:x}'
      end
      iterator :on_val => 'c, d', :to => 'f:y' do
        echo '${f:y}'
      end
      iterator :on_val => 'e, f', :to => 'v:z' do
        echo '${v:z}'
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal %w[ a b c d e f ], @tracer.to_a
  end

  PDEF0 = Ruote.process_definition :name => 'test' do
    sequence do
      iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
      echo 'done.'
    end
  end

  def test_break

    @dashboard.register_participant '.*' do |workitem|

      tracer << "#{workitem.participant_name}\n"

      if workitem.participant_name == 'bob'
        workitem.fields['__command__'] = [ 'break', nil ]
      end
    end

    #noisy

    assert_trace(%w[ alice bob done. ], PDEF0)
  end

  def test_rewind

    stash[:rewound] = false

    @dashboard.register_participant '.*' do |workitem|

      tracer << "#{workitem.participant_name}\n"

      if (not context.stash[:rewound]) and workitem.participant_name == 'bob'
        context.stash[:rewound] = true
        workitem.fields['__command__'] = [ 'rewind', nil ]
      end
    end

    #noisy

    assert_trace(%w[ alice bob alice bob charly done. ], PDEF0)
  end

  def test_skip

    @dashboard.register_participant '.*' do |workitem|

      tracer << "#{workitem.participant_name}\n"

      if workitem.participant_name == 'alice'
        workitem.fields['__command__'] = [ 'skip', 1 ]
      end
    end

    #noisy

    assert_trace(%w[ alice charly done.], PDEF0)
  end

  def test_jump

    @dashboard.register_participant '.*' do |workitem|

      tracer << "#{workitem.participant_name}\n"

      if workitem.participant_name == 'alice'
        workitem.fields['__command__'] = [ 'jump', -1 ]
      end
    end

    #noisy

    assert_trace(%w[ alice charly done.], PDEF0)
  end

  def test_skip_command

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        sequence do
          participant '${v:v}'
          skip 1, :if => '${v:v} == alice'
        end
      end
    end

    @dashboard.register_participant '.*' do |workitem|
      tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(%w[ alice/0_0_0_0 charly/0_0_0_0 ], pdef)
  end

  def test_break_if

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'a, b, c', :to_var => 'v', :break_if => '${v:v} == b' do
        participant '${v:v}'
      end
    end

    @dashboard.register_participant '.*' do |workitem|
      tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(%w[ a/0_0_0 b/0_0_0 ], pdef)
  end

  def test_break_unless

    pdef = Ruote.process_definition :name => 'test' do
      set :var => 'v', :val => 'a'
      iterator :on_val => 'a, b, c', :to_var => 'v', :break_unless => '${v:v} == a' do
        participant '${v:v}'
      end
    end

    @dashboard.register_participant '.*' do |workitem|
      tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(%w[ a/0_1_0 b/0_1_0 ], pdef)
  end

  def test_iterator_with_hash_as_input

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => { 'a' => 'A', 'b' => 'B' }, :to_f => 'f' do
        p1
      end
    end

    @dashboard.register_participant :p1 do |wi|
      tracer << wi.fields['f'].join(':')
      tracer << "\n"
    end

    #noisy

    assert_trace %w[ a:A b:B ], pdef
  end

  def test_implicit_i_variable

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly' do
        participant '${v:i}:${v:ii}'
      end
    end

    @dashboard.register_participant '.*' do |workitem|
      tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[ alice:0/0_0_0 bob:1/0_0_0 charly:2/0_0_0 ], @tracer.to_a

    assert_equal 'charly', r['variables']['i']
    assert_equal 2, r['variables']['ii']
  end

  def test_nested_break

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on => 'a, b, c', :tag => 'it' do
        sequence do
          echo '0_${v:i}'
          cursor do
            echo '1_${v:i}'
            _break :ref => 'it'
            echo '11_${v:i}'
          end
          echo '2_${v:i}'
        end
      end
    end

    #noisy

    assert_trace %w[ 0_a 1_a ], pdef
  end

  def test_external_break

    pdef = Ruote.process_definition :name => 'test' do
      concurrence do
        iterator :on => (1..1000).to_a, :tag => 'it' do
          echo '${v:i}'
        end
        sequence do
          sequence do
            _break :ref => 'it'
          end
        end
      end
    end

    #noisy

    assert_trace %w[ 1 2 ], pdef
  end

  def test_implicit_sequence

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        echo '0:${v:v}'
        echo '1:${v:v}'
      end
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal(
      %w[
        0:alice 1:alice
        0:bob 1:bob
        0:charly 1:charly
      ],
      @tracer.to_a)
  end
end

