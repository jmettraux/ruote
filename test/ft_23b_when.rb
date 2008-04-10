
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest23b < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestWhen23b0 < OpenWFE::ProcessDefinition
        process_definition :name => "23b_when0", :revision => "0" do
            concurrence do
                _when :test => "false == true", :timeout => "1s500" do
                    _print "la vaca vuela"
                end
                _print "ok"
            end
        end
    end

    #
    # Testing if the conditional _when got correctly unscheduled.
    #
    def test_0

        #log_level_to_debug

        dotest TestWhen23b0, "ok"
    end


    #
    # Test 1
    #

    class TestWhen23b1 < OpenWFE::ProcessDefinition
        concurrence do
            _when :test => "true == true" do
            end
            _print "ok"
        end
    end

    #
    # Testing an empty _when
    #
    def test_1

        #log_level_to_debug

        dotest TestWhen23b1, "ok"
    end

end

