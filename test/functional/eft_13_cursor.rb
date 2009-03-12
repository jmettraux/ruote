
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Mar 12 10:59:47 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftCursorTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cursor

    pdef = OpenWFE.process_definition :name => 'test' do
      cursor do
        echo 'a'
        echo 'b'
      end
    end
    assert_trace(pdef, "a\nb")
  end

  def test_cursor_break

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        cursor do
          echo 'a'
          _break
          echo 'b'
        end
        echo 'c'
      end
    end
    assert_trace(pdef, "a\nc")
  end

  def test_cursor_skip

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        cursor do
          echo 'a'
          skip :step => 2
          echo 'b'
        end
        echo 'c'
      end
    end
    assert_trace(pdef, "a\nc")
  end

  def test_cursor_back

    pdef = OpenWFE.process_definition :name => 'test' do
      cursor do
        echo 'a'
        skip 3
        echo 'b'
        skip 2
        back 2
        echo 'c'
      end
    end
    assert_trace(pdef, "a\nb\nc")
  end

  def test_cursor_rewind

    pdef = OpenWFE.process_definition :name => 'test' do
      cursor do
        echo 'a'
        bravo
        echo 'c'
      end
    end

    counter = 0

    @engine.register_participant 'bravo' do |workitem|
      counter = counter + 1
      workitem.__cursor_command__ = 'rewind' unless counter > 2
    end

    assert_trace(pdef, "a\na\na\nc")
  end

  def test_cursor_break_if

    pdef = OpenWFE.process_definition :name => 'test' do
      cursor :break_if => '${f:rejected}' do
        alpha
        alpha
        alpha
        alpha # will get forgotten
      end
    end

    counter = 0

    @engine.register_participant 'alpha' do |workitem|
      @tracer << counter.to_s
      workitem.rejected = (counter == 2)
      counter = counter + 1
    end

    assert_trace(pdef, '012')
  end

  def test_cursor_break_unless

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        set :f => 'accepted', :val => true
        cursor :break_unless => '${f:accepted}' do
          alpha
          alpha
          alpha
          alpha # will get forgotten
        end
      end
    end

    counter = 0

    @engine.register_participant 'alpha' do |workitem|
      @tracer << counter.to_s
      workitem.accepted = (counter != 2)
      counter = counter + 1
    end

    assert_trace(pdef, '012')
  end
end

