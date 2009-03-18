
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Mar 13 15:33:03 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftRedoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_redo

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence :tag => 'seq0' do
          echo 'a'
          wait '010'
          echo 'b'
        end
        _redo :ref => 'seq0'
      end
    end
    assert_trace(pdef, "a\na\nb")
  end

  def test_redo_conditional

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence :tag => 'seq0' do
          echo 'a'
          wait '010'
          echo 'b'
        end
        _redo :ref => 'seq0', :if => '${f:redo}'
      end
    end

    li = OpenWFE::LaunchItem.new(pdef)
    assert_trace(li, "a\nb", :no_purge => true)

    @tracer.clear

    li = OpenWFE::LaunchItem.new(pdef)
    li.redo = true
    assert_trace(li, "a\na\nb")
  end

  def test_redo_multiple_times

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence :tag => 'seq0' do
          echo 'a'
          wait '010'
          echo 'b'
        end
        sequence do
          _redo :ref => 'seq0'
          _redo :ref => 'seq0'
        end
      end
    end
    assert_trace(pdef, %w{ a a a b }.join("\n"))
  end

  #def test_redo_after
  #  pdef = OpenWFE.process_definition :name => 'test' do
  #    concurrence do
  #      sequence :tag => '/seq0' do
  #        echo 'a'
  #        echo 'b'
  #      end
  #      sequence do
  #        wait '010'
  #        _redo :ref => 'seq0'
  #      end
  #    end
  #  end
  #  assert_trace(pdef, %w{ a b a b }.join("\n"))
  #end
end

