
#
# Testing Ruote (OpenWFEru)
#
# Mon Jun 29 18:34:02 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class EftCursorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_cursor

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
      end
    end

    #noisy

    assert_trace(pdef, '')
  end

  def test_cursor

    pdef = Ruote.process_definition :name => 'test' do
      cursor do
        echo 'a'
        echo 'b'
      end
    end

    #noisy

    assert_trace(pdef, %w[ a b ])
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

    assert_trace(pdef, %w[ a c ])
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

    assert_trace(pdef, 'a')
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

    assert_trace(pdef, %w[ a c ])
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

    assert_trace(pdef, %w[ a b d ])
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

    assert_trace(pdef, %w[ a ] * 5)
  end
end

