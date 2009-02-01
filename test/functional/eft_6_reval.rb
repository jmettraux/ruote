
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sun Jan 25 17:05:36 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftRevalTest < Test::Unit::TestCase
  include FunctionalBase

  def test_0

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        _print 'toto'
      end
    end

    assert_trace(
      pdef,
      %w{ toto }.join("\n"))

    # TODO : continue me !
  end
end

