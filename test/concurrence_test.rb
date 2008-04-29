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

require 'openwfe/engine/engine'
require 'openwfe/def'
require 'openwfe/participants/storeparticipants'


class ConcurrenceAndParticipantTest < Test::Unit::TestCase

    def setup
        @engine = Engine.new
    end

    #def teardown
    #end

    #
    # concurrence test

    class Hpc0 < OpenWFE::ProcessDefinition
        concurrence do
            #participant :alice
            #participant :bob
            alice
            bob
        end
    end

    def test_hpc_0

        @hpAlice = OpenWFE::HashParticipant.new
        @hpBob = OpenWFE::HashParticipant.new

        @engine.register_participant :alice, @hpAlice
        @engine.register_participant :bob, @hpBob

        @engine.launch Hpc0

        sleep 0.100

        assert_equal @hpAlice.size, 1
        assert_equal @hpBob.size, 1
    end

    def test_1

        @engine.register_participant :alice do |workitem|
            puts "alice in"
            sleep 0.100
            puts "alice out"
        end
        @engine.register_participant :bob do |workitem|
            puts "bob in"
            sleep 0.100
            puts "bob out"
        end

        @engine.launch Hpc0

        sleep 2
    end

end

