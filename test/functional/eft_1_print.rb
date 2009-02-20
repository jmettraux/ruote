
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require File.dirname(__FILE__) + '/base'


class EftPrintTest < Test::Unit::TestCase
  include FunctionalBase

  class Test0 < OpenWFE::ProcessDefinition
    _print 'a'
  end

  def test_print
    assert_trace(Test0, 'a')
  end

  def test_print_xml
    assert_trace(%{
<process-definition name="test"><print>b</print></process-definition>
      },
      'b')
  end

  def test_print_escape

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        set :v => 'toto', :value => 'otot'
        echo '${toto}', :escape => 'true'
        echo '${toto}', :escape => true
        echo :escape => true do
          '${toto}'
        end
      end
    end

    assert_trace(
      pdef,
      ([ '${toto}' ] * 3).join("\n"))
  end

  def test_echo

    pdef = OpenWFE.process_definition :name => 'test' do
      echo 'Prokofief'
    end
    assert_trace(pdef, 'Prokofief')
  end
end

