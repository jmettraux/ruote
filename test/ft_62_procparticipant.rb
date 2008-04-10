
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Jul  9 10:25:18 JST 2007
#

require 'rubygems'

require 'openwfe/def'
require 'flowtestbase'


class FlowTest62 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # TEST 0

    class SubDef < OpenWFE::ProcessDefinition
        _print "subruby"
    end

    SUBDEF = '''
        <process-definition name="sub" revision="0">
            <print>subxml</print>
        </process-definition>
    '''.strip

    class TestDefinition0 < OpenWFE::ProcessDefinition
        sequence do
            _print "main0"
            subruby
            subxml
            subfile
            _print "main1"
        end
    end

    def test_0

        #$OWFE_LOG.level = Logger::DEBUG

        engine.register_participant(
            "subruby", 
            OpenWFE::ProcessParticipant.new(SubDef))
        engine.register_participant(
            "subxml", 
            OpenWFE::ProcessParticipant.new(SUBDEF))

        File.open "work/procdef62.xml", "w+" do |f|
            f.write SUBDEF
            f.write "\n"
        end
        engine.register_participant(
            "subfile", 
            OpenWFE::ProcessParticipant.new('file:work/procdef62.xml'))

        dotest TestDefinition0, "main0\nsubruby\nsubxml\nsubxml\nmain1"
    end

end

