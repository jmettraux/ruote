
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
  def test_empty_sequence
    assert_trace(Test0, '')
  end

  def test_a_b_sequence
    assert_trace(
      OpenWFE.process_definition(:name => 'test_1') {
        sequence do
          echo 'a'
          echo 'b'
        end
      },
      "a\nb")
  end

  def test_a_b_sequence_xml
    assert_trace(%{
<process-definition name="test">
  <sequence>
    <echo>a</echo>
    <echo>b</echo>
  </sequence>
</process-definition>
      },
      "a\nb")
  end
end

