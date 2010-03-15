
#
# testing ruote
#
# Mon Jun 29 09:35:48 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


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

  def test_iterator

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_var => 'v' do
        participant '${v:v}'
      end
    end

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(%w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ], pdef)
  end

  def test_to_f

    pdef = Ruote.process_definition :name => 'test' do
      iterator :on_val => 'alice, bob, charly', :to_field => 'f' do
        participant '${f:f}'
      end
    end

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.fields['f']}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(%w[ alice/0_0_0 bob/0_0_0 charly/0_0_0 ], pdef)
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

    @engine.register_participant '.*' do |workitem|

      @tracer << "#{workitem.participant_name}\n"

      workitem.fields['__command__'] = [ 'break', nil ] \
        if workitem.participant_name == 'bob'
    end

    #noisy

    assert_trace(%w[ alice bob done. ], PDEF0)
  end

  def test_rewind

    rewound = false

    @engine.register_participant '.*' do |workitem|

      @tracer << "#{workitem.participant_name}\n"

      if (not rewound) and workitem.participant_name == 'bob'
        rewound = true
        workitem.fields['__command__'] = [ 'rewind', nil ]
      end
    end

    #noisy

    assert_trace(%w[ alice bob alice bob charly done. ], PDEF0)
  end

  def test_skip

    @engine.register_participant '.*' do |workitem|

      @tracer << "#{workitem.participant_name}\n"

      workitem.fields['__command__'] = [ 'skip', 1 ] \
        if workitem.participant_name == 'alice'
    end

    #noisy

    assert_trace(%w[ alice charly done.], PDEF0)
  end

  def test_jump

    @engine.register_participant '.*' do |workitem|

      @tracer << "#{workitem.participant_name}\n"

      workitem.fields['__command__'] = [ 'jump', -1 ] \
        if workitem.participant_name == 'alice'
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

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
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

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
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

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
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

    @engine.register_participant :p1 do |wi|
      @tracer << wi.fields['f'].join(':')
      @tracer << "\n"
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

    @engine.register_participant '.*' do |workitem|
      @tracer << "#{workitem.participant_name}/#{workitem.fei.expid}\n"
    end

    #noisy

    assert_trace(%w[ alice:0/0_0_0 bob:1/0_0_0 charly:2/0_0_0 ], pdef)
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
end

