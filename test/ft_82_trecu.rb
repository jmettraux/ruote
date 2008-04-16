
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


class FlowTest82 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class Test0 < OpenWFE::ProcessDefinition
        sequence do
            #_print "${r:fei.wfname}"
            _print do
                reval "$i += 1"
            end
            subprocess :ref => "Test", :unless => "${r:$i} == 3"
        end
    end

    def test_0

        log_level_to_debug

        $i = 0

        dotest Test0, "1\n2\n3"
    end

end

