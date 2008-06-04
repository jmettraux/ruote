
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Mar  9 20:43:02 JST 2008
#

require 'flowtestbase'

require 'openwfe/def'
require 'openwfe/participants/storeparticipants'
require 'openwfe/storage/yamlcustom'


class FlowTest84b < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # TEST 0

    class Test0 < OpenWFE::ProcessDefinition
       sub0
       define "sub0" do
           toto
       end
    end

    def test_0

        #log_level_to_debug

        @engine.register_participant :toto, OpenWFE::NullParticipant

        fei = @engine.launch Test0

        sleep 0.350

        ps = @engine.process_stack fei.wfid, true

        #p ps.collect { |fexp| fexp.fei.to_s }

        assert_equal 7, ps.size

        assert_equal(
            ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sub0", {"ref"=>"sub0"}, []], ["define", {}, ["sub0", ["toto", {"ref"=>"toto"}, []]]]]],
            ps.representation)

        assert_equal(
            ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sub0", {"ref"=>"sub0"}, []], ["define", {}, ["sub0", ["toto", {"ref"=>"toto"}, []]]]]],
            @engine.process_representation(fei.wfid))
    end

end

