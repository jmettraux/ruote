
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftProcessDefinitionTest < Test::Unit::TestCase
  include FunctionalBase

  class Test0 < OpenWFE::ProcessDefinition
  end
  def test_0
    assert_trace(Test0, '')
  end

  def test_1
    assert_trace(OpenWFE.process_definition(:name => 'test_1') { }, '')
  end

  def test_2
    assert_trace(%{
<process-definition name="test">
</process-definition>
      },
      '')
  end
end

