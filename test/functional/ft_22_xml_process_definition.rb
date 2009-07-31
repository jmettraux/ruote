
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Jul 31 10:21:51 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtXmlProcessDefinitionTest < Test::Unit::TestCase
  include FunctionalBase

  def test_sequence

    pdef = %{
<process-definition name="test">
  <sequence>
    <echo>a</echo>
    <echo>b</echo>
  </sequence>
</process-definition>
    }

    #noisy

    assert_trace(pdef, %w[ a b ])
  end
end

