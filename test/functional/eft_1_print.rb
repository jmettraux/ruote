
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

  def test_0
    assert_trace(Test0, 'a')
  end

  def test_1
    assert_trace(%{
<process-definition name="test"><print>b</print></process-definition>
      },
      'b')
  end
end

