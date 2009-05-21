
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Sep 20 23:40:10 JST 2008
#

require File.dirname(__FILE__) + '/base'


class EftEchoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_echo

    pdef = Ruote.process_definition :name => 'test' do
      echo 'a'
    end

    #noisy

    assert_trace(pdef, 'a')
  end

  #def test_print_escape
  #  pdef = OpenWFE.process_definition :name => 'test' do
  #    sequence do
  #      set :v => 'toto', :value => 'otot'
  #      echo '${toto}', :escape => 'true'
  #      echo '${toto}', :escape => true
  #      echo :escape => true do
  #        '${toto}'
  #      end
  #    end
  #  end
  #  assert_trace(
  #    pdef,
  #    ([ '${toto}' ] * 3).join("\n"))
  #end
end

