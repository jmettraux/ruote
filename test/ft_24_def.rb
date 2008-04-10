
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'rubygems'

require 'flowtestbase'
require 'openwfe/def'

#
# just testing the
#
#     require 'openwfe/def'
#
# shortcut
#

class FlowTest24 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestDefinition0 < OpenWFE::ProcessDefinition
        _print "ok"
    end

    def test_0

        dotest TestDefinition0, "ok"
    end

end

