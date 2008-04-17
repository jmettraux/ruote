
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Tue Apr  8 12:59:05 JST 2008
#

require 'flowtestbase'
require 'openwfe/def'


class FlowTest23d < Test::Unit::TestCase
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
            _when :test => "false == true", :timeout => "1s500" do
                _print "la vaca vuela"
            end
            _print "ok"
        end
    end

    #
    # Testing if the conditional _when got correctly unscheduled.
    #
    def test_0

        #log_level_to_debug

        fei = launch Test0

        sleep 0.350

        #puts @engine.get_expression_storage
        assert_equal 6, @engine.get_expression_storage.size

        @engine.cancel_process fei

        sleep 0.350

        assert_equal 1, @engine.get_expression_storage.size
    end

end

