
#
# testing ruote
#
# Mon Jun 29 18:34:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/no_op_participant'


class EftCursorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_cursor

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
      end
    end

    #noisy

    assert_trace('', pdef)
  end

  def test_cursor

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        echo 'a'
        echo 'b'
      end
    end

    #noisy

    assert_trace(%w[ a b ], pdef)
  end

  def test_skip

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        echo 'a'
        skip 1
        echo 'b'
        echo 'c'
      end
    end

    #noisy

    assert_trace(%w[ a c ], pdef)
  end

  def test_break

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        echo 'a'
        _break
        echo 'b'
      end
    end

    #noisy

    assert_trace('a', pdef)
  end

  def test_stop

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        echo 'a'
        stop
        echo 'b'
      end
    end

    #noisy

    assert_trace('a', pdef)
  end

  def test_jump_to_tag

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        echo 'a'
        jump :to => 'c'
        echo 'b'
        echo 'c', :tag => 'c'
      end
    end

    #noisy

    assert_trace(%w[ a c ], pdef)
  end

  def test_jump_to_variable_tag

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        echo 'a'
        jump :to => 'd'
        echo 'b'
        set :var => 'v0', :val => 'd'
        jump :to => 'd'
        echo 'c'
        echo 'd', :tag => '${v:v0}'
      end
    end

    #noisy

    assert_trace(%w[ a b d ], pdef)
  end

  def test_rewind_if

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        set :f => 'counter', :val => 0
        set :f => 'rewind', :val => false
        cursor :rewind_if => '${f:rewind}' do
          alpha
        end
      end
    end

    @engine.register_participant :alpha do |workitem|
      workitem.fields['counter'] += 1
      workitem.fields['rewind'] = workitem.fields['counter'] < 5
      @tracer << "a\n"
    end

    #noisy

    assert_trace(%w[ a ] * 5, pdef)
  end

  def test_jump_to

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        author
        reviewer
        jump :to => 'author', :if => '${not_ok}'
        publisher
      end
    end

    count = 0
      # closures ftw

    @engine.register_participant :author do |workitem|
      @tracer << "a\n"
      count = count + 1
    end
    @engine.register_participant :reviewer do |workitem|
      @tracer << "r\n"
      workitem.fields['not_ok'] = (count < 3)
    end
    @engine.register_participant :publisher do |workitem|
      @tracer << "p\n"
    end

    #noisy

    assert_trace %w[ a r a r a r p ], pdef
      # ARP nostalgy....
  end

  def test_deep_rewind

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        sequence do
          echo 'a'
          rewind
          echo 'b'
        end
      end
    end

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(14)

    #p @tracer.to_s

    assert_equal [ 'a', 'a' ], @tracer.to_a[0..1]
  end

  def test_external_break

    pdef = Ruote.process_definition :name => 'test' do
      concurrence do
        repeat :tag => 'cu' do
          echo 'a'
        end
        sequence do
          wait '1.1'
          stop :ref => 'cu'
          alpha
        end
      end
    end

    @engine.register_participant :alpha, Ruote::NoOpParticipant.new

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)
    wait_for(wfid)

    #p @tracer.to_s
    assert_equal %w[ a a a ], @tracer.to_a[0, 3]

    assert_nil @engine.process(wfid)
  end

  def test_nested_break

    pdef = Ruote.process_definition :name => 'test' do
      cursor :tag => 'cu' do
        echo 'a'
        cursor do
          echo 'b'
          _break :ref => 'cu'
          echo 'c'
        end
        echo 'd'
      end
    end

    #noisy

    assert_trace %w[ a b ], pdef
  end

  def test_break_if

    pdef = Ruote.process_definition :name => 'test' do
      cursor :break_if => 'true' do
        echo 'c'
      end
      echo 'done.'
    end

    #noisy

    assert_trace 'done.', pdef
  end

  def test_over_unless

    pdef = Ruote.process_definition :name => 'test' do
      cursor :over_unless => 'false' do
        echo 'c'
      end
      echo 'done.'
    end

    #noisy

    assert_trace 'done.', pdef
  end
end

