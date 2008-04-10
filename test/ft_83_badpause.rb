
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Sat Feb 16 19:07:42 JST 2008
#

require 'flowtestbase'
#require 'openwfe/def'
#require 'openwfe/worklist/storeparticipant'

#include OpenWFE


class FlowTest83 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class Test0 < OpenWFE::ProcessDefinition
        concurrence do
            _loop do
                alpha
            end
            _loop do
                alpha
            end
        end
    end

    def test_0

        @engine.register_participant :alpha do
            sleep 0.002
        end

        fei = @engine.launch Test0

        sleep 0.350

        1000.times do |i|
            print "."
            ps = @engine.process_status fei
            assert ( ! ps.paused?)
            #p ps.expressions.size
        end

        #dotest Test0, "1\n2\n3"
    end

end

