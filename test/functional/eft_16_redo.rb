
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
end

