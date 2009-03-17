
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Mar 13 15:02:22 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftUndoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_undo

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence :tag => 'seq0' do
          echo 'a'
          wait '1s'
          echo 'b'
        end
        undo :ref => 'seq0'
      end
    end
    assert_trace(pdef, 'a')
  end

  def test_undo_shorter

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence :tag => 'seq0' do
          echo 'a'
          wait '1s'
          echo 'b'
        end
        undo 'seq0'
      end
    end
    assert_trace(pdef, 'a')
  end

  def test_undo_within

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence :tag => 'seq0' do
          echo 'a'
          undo :ref => 'seq0'
          echo 'b'
        end
      end
    end
    assert_trace(pdef, 'a')
  end

  def test_undo_conditional

    pdef = OpenWFE.process_definition :name => 'test' do
      concurrence do
        sequence :tag => 'seq0' do
          echo 'a'
          undo :ref => 'seq0', :if => '${field:over}'
          echo 'b'
          set :f => 'over', :val => true
          undo :ref => 'seq0', :if => '${field:over}'
          echo 'c'
        end
      end
    end
    assert_trace(pdef, "a\nb")
  end
end

