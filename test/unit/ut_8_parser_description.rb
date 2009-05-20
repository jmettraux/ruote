
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Mon Oct 15 08:42:08 JST 2007
#

require File.dirname(__FILE__) + '/../test_helper.rb'

require 'openwfe/expool/def_parser'


class ParserDescriptionTest < Test::Unit::TestCase

  DEF0 = %{
class MyDef0 < OpenWFE::ProcessDefinition
  description 'not much to say'
  sequence do
  end
end
  }

  def test_0

    #rep = OpenWFE::SimpleExpRepresentation.from_code DEF0
    #rep = OpenWFE::DefParser.parse_string DEF0
    rep = OpenWFE::DefParser.parse DEF0

    assert_equal(
      'not much to say',
      OpenWFE::ExpressionTree.get_description(rep))
  end

  DEF1 = <<-EOS
<process-definition name="x" revision="y">
  <description>
    just a tiny process
  </description>
  <participant ref="nada" />
</process-definition>
  EOS

  def test_1

    rep = OpenWFE::DefParser.parse DEF1

    assert_equal(
      'just a tiny process',
      OpenWFE::ExpressionTree.get_description(rep))
  end

  class Test2 < OpenWFE::ProcessDefinition
    # no description
    sequence do
    end
  end
  class Test2b < OpenWFE::ProcessDefinition
    # no description
    sequence do
    end
    define :name => "sub0" do
    end
  end

  def test_2

    tree = OpenWFE::DefParser.parse Test2
    assert_nil OpenWFE::ExpressionTree.get_description(tree)

    tree = OpenWFE::DefParser.parse Test2b
    assert_nil OpenWFE::ExpressionTree.get_description(tree)
  end
end

