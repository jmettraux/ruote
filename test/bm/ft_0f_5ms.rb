
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Wed Apr 16 15:33:59 JST 2008
#

require 'flowtestbase'


class FlowTest0b < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    class Test5ms < OpenWFE::ProcessDefinition
        concurrence do
            _print "a"
            _print "b"
        end
    end

    def test_0

        dotest Test5ms, "a\nb"
    end

end

