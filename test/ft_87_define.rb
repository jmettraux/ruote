#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon May  5 09:28:28 JST 2008
#

require 'rubygems'

require 'flowtestbase'

require 'openwfe/def'


class FlowTest87 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # TEST 0

    class Test0 < OpenWFE::ProcessDefinition

        sequence do
            sub0
            sub1
            sub2
            sub3
        end

        process_definition :name => "sub0" do
            _print "sub0"
        end
        define :name => "sub1" do
            _print "sub1"
        end
        process_definition "sub2" do
            _print "sub2"
        end
        define "sub3" do
            _print "sub3"
        end
    end

    def test_0

        dotest Test0, %w{ sub0 sub1 sub2 sub3 }.join("\n")
    end

    #
    # TEST 1

    class Test1 < OpenWFE::ProcessDefinition
        sequence do
            "bad 0"
            _print "ok"
            "bad 1"
            _print "over"
        end
    end

    def test_1

        dotest Test1, "ok\nover"
    end

end

