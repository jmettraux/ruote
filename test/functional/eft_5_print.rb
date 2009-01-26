
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Jan 25 16:59:34 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftPrintTest < Test::Unit::TestCase
  include FunctionalBase

  def test_0

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        set :v => 'toto', :value => 'otot'
        _print '${toto}', :escape => 'true'
        _print '${toto}', :escape => true
      end
    end

    assert_trace(
      pdef,
      %w{ ${toto} ${toto} }.join("\n"))
  end
end

