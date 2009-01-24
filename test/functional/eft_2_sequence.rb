
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Sat Jan 24 22:40:35 JST 2009
#

require File.dirname(__FILE__) + '/base'


class EftSequenceTest < Test::Unit::TestCase
  include FunctionalBase

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
    end
  end
  def test_0
    assert_trace(Test0, '')
  end

  def test_1
    assert_trace(
      OpenWFE.process_definition(:name => 'test_1') {
        sequence do
          _print 'a'
          _print 'b'
        end
      },
      "a\nb")
  end

  def test_2
    assert_trace(%{
<process-definition name="test">
  <sequence>
    <print>a</print>
    <print>b</print>
  </sequence>
</process-definition>
      },
      "a\nb")
  end
end

