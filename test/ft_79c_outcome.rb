
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#
# Fri May  9 13:43:26 JST 2008
#

require 'flowtestbase'


class FlowTest79c < Test::Unit::TestCase
    include FlowTestBase

    class Test0 < OpenWFE::ProcessDefinition

        sequence do
            step :alpha
        end

        define "ichi" do
        end
        define "ni" do
        end
    end

    def test_0

        @engine.register_participant :alpha do |wi|
            @tracer << "alpha"
        end

        dotest Test0, ""
    end
end

