
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct 15 08:42:08 JST 2007
#

require 'test/unit'

require 'openwfe/expool/parser'

#
# testing definition.get_description
#

class DescriptionTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    DEF0 = """
class MyDef0 < OpenWFE::ProcessDefinition
    description 'not much to say'
    sequence do
    end
end
    """

    def test_0

        #rep = OpenWFE::SimpleExpRepresentation.from_code DEF0
        rep = OpenWFE::DefParser.parse_string DEF0

        assert_equal(
            "not much to say", 
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

        rep = OpenWFE::DefParser.parse_string DEF1

        assert_equal(
            "just a tiny process",
            OpenWFE::ExpressionTree.get_description(rep))
    end
end

