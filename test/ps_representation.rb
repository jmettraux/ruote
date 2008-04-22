
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Apr  8 18:33:11 JST 2008
#

require 'rubygems'

require 'test/unit'

require 'openwfe/engine'


class PsRepresentationTest < Test::Unit::TestCase

    def setup

        @engine = OpenWFE::Engine.new :definition_in_launchitem_allowed => true
    end

    def teardown

        @engine.stop if @engine
    end

    #
    # TESTS

    class Test0 < OpenWFE::ProcessDefinition
        sequence do
            alpha
            bravo
        end
    end

    def test_0

        @engine.register_participant "alpha", OpenWFE::NullParticipant

        fei = @engine.launch Test0

        sleep 0.350

        ps = @engine.process_stack fei, true

        #p ps.representation

        assert_equal(
            ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sequence", {}, [["alpha", {"ref"=>"alpha"}, []], ["bravo", {}, []]]]]],
            ps.representation)

        #
        # change process instance (charly instead of bravo)

        #puts ps.collect { |fexp| fexp.fei.to_s }.join("\n")

        bravo_fei = ps.find { |fexp| fexp.fei.expid == "0.0.1" }.fei

        @engine.update_raw_expression bravo_fei, ["charly", {}, []]

        ps = @engine.process_stack fei, true

        assert_equal(
            ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sequence", {}, [["alpha", {"ref"=>"alpha"}, []], ["charly", {}, []]]]]],
            ps.representation)
    end

    # see also test/ft_84_updateexp.rb

end
