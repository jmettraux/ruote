
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Wed Aug  5 09:44:31 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtLaunchitemsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launchitem

    pdef = Ruote.process_definition :name => 'test' do
      sequence do
        echo '${f:car}'
      end
    end

    li = Ruote::Launchitem.new(pdef, 'car' => 'benz')

    assert_trace(li, 'benz')
  end
end

