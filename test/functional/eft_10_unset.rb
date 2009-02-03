
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Feb  3 16:40:16 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftUnsetTest < Test::Unit::TestCase
  include FunctionalBase

   # TODO : fill in the blanks !

  def test_unset_variables

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
      end
    end

    assert_trace(pdef, '')
  end

  def test_unset_fields

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
      end
    end

    assert_trace(pdef, '')
  end
end

