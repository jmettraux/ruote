#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 15:41:44 JST 2006
#
# Kita Yokohama
#

require 'test/unit'

require 'openwfe/flowexpressionid'
require 'openwfe/engine/engine'
require 'openwfe/def'
require 'openwfe/participants/storeparticipants'


class HParticipantTest < Test::Unit::TestCase

    def setup

        @engine = Engine.new({ :definition_in_launchitem_allowed => true })
    end

    def teardown

        @engine.stop if @engine
    end

    class HpDefinition0 < OpenWFE::ProcessDefinition
        sequence do
            participant :alice
            participant :bob
        end
    end

    def test_hp_0

        @hpAlice = HashParticipant.new
        @hpBob = HashParticipant.new

        @engine.register_participant :alice, @hpAlice
        @engine.register_participant :bob, @hpBob

        do_test
    end

    def test_hp_1

        #FileUtils.remove_dir "./work" if File.exist? "./work"
        FileUtils.rm_rf "work" if File.exist? "./work"

        @engine.application_context[:work_directory] = "./work"
        @hpAlice = YamlParticipant.new("alice", @engine.application_context)
        #@hpBob = YamlParticipant.new("bob", @engine.application_context)

        @engine.register_participant(:alice, @hpAlice)
        #@engine.register_participant(:bob, @hpBob)
        @hpBob = @engine.register_participant(:bob, YamlParticipant)

        do_test
    end

    def do_test

        id = @engine.launch HpDefinition0

        assert \
            id.kind_of?(FlowExpressionId),
            "engine.launch() doesn't return an instance of FlowExpressionId "+
            "but of #{id.class}"

        #puts id.to_s

        #puts "alice count : #{@hpAlice.size}"
        #puts "bob count :   #{@hpBob.size}"

        sleep 0.350

        assert_equal 0, @hpBob.size
        assert_equal 1, @hpAlice.size

        wi = @hpAlice.list_workitems(id.workflow_instance_id)[0]

        assert \
            wi != nil,
            "didn't find wi for flow #{id.workflow_instance_id}"

        wi.message = "Hello bob !"

        @hpAlice.forward(wi)

        sleep 0.350

        assert_equal 0, @hpAlice.size
        assert_equal 1, @hpBob.size

        wi = @hpBob.list_workitems(id.workflow_instance_id)[0]

        assert_equal wi.message, "Hello bob !"

        @hpBob.proceed wi

        sleep 0.350

        assert_equal 0, @hpAlice.size
        assert_equal 0, @hpBob.size

        assert_equal 1, @engine.get_expression_storage.size
    end

    def test_d_0

        @hpAlice = HashParticipant.new
        @hpBob = HashParticipant.new

        @engine.register_participant :alice, @hpAlice
        @engine.register_participant :bob, @hpBob

        id = @engine.launch HpDefinition0

        sleep 0.350

        assert_equal 1, @hpAlice.size
        assert_equal 0, @hpBob.size

        wi = @hpAlice.first_workitem

        @hpAlice.delegate wi, @hpBob

        assert_equal 0, @hpAlice.size
        assert_equal 1, @hpBob.size

        wi = @hpBob.first_workitem

        @hpBob.proceed wi

        sleep 0.350

        assert_equal 0, @hpAlice.size
        assert_equal 1, @hpBob.size

        wi = @hpBob.first_workitem

        @hpBob.delegate wi.fei, @hpAlice

        assert_equal 1, @hpAlice.size
        assert_equal 0, @hpBob.size

        wi = @hpAlice.first_workitem

        @hpAlice.forward wi

        sleep 0.350

        assert_equal 0, @hpAlice.size
        assert_equal 0, @hpBob.size

        assert_equal 1, @engine.get_expression_storage.size
    end

end

