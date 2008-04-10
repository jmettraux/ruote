
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest42 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end


    #
    # Test 0
    #

    class TestCase42a0 < OpenWFE::ProcessDefinition
        sequence do
            set :variable => "v", :value => "a"
            concurrence do
                set :variable => "v", :value => "b"
                set :variable => "v", :value => "c"
                forget do
                    set :variable => "v", :value => "d"
                end
            end
            _print "v:${v}"
        end
    end

    def test_0

        dotest TestCase42a0, [ "v:b", "v:c" ]
    end


    #
    # Test 1
    #

    # DISABLED

    class TestCase42a1 < OpenWFE::ProcessDefinition
        sequence do
            set :variable => "v", :value => "a"
            concurrence :count => 2 do
                set :variable => "v", :value => "b"
                set :variable => "v", :value => "c"
                lose do
                    set :variable => "v", :value => "d"
                end
            end
            _print "v:${v}"
        end
    end

    def _test_1

        dotest(
            TestCase42a1, 
            "v:d",
            true)
    end

end

