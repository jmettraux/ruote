
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Sep 11 21:32:10 JST 2007
#

require 'openwfe/def'

require 'flowtestbase'


class FlowTest68 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end

    #
    # TEST 0

    class Test0 < ProcessDefinition
        sequence do
            alpha :id => 0
            alpha :id => 1, :if => "${r:$count > 1}"
            alpha :id => 2
            alpha :id => 3, :if => "${r:$count > 1}"
        end
    end

    def test_0

        #log_level_to_debug

        $count = 0

        @engine.register_participant :alpha do |workitem|
            @tracer << "#{workitem.params["id"]} #{$count}\n"
            $count += 1
        end

        dotest(Test0, "0 0\n2 1\n3 2")
    end

    #
    # TEST 1

    class Test1 < ProcessDefinition
        sequence do
            subp :id => 0
            subp :id => 1, :unless => "true"
            subp :id => 2
        end
        process_definition :name => "subp" do
            _print "${id}"
        end
    end

    def test_0

        dotest(Test1, "0\n2")
    end

end

