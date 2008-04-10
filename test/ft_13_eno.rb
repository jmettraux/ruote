
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Jan  2 13:14:37 JST 2007
#

require 'openwfe/def'
require 'openwfe/participants/participants'
require 'openwfe/participants/enoparticipants'
require 'flowtestbase'


class FlowTest13 < Test::Unit::TestCase
    include FlowTestBase

    #def setup
    #end

    #def teardown
    #end

    #
    # Test 0
    #

    class TestDefinition0 < OpenWFE::ProcessDefinition
        def make
            process_definition :name => "test0", :revision => "0" do
                sequence do
                    set :field => 'email_target' do
                        "whatever56x56@gmail.com"
                    end
                    set :field => 'customer_name' do
                        "Monsieur Toto"
                    end
                    participant :ref => 'eno'
                    _print "ok"
                end
            end
        end
    end

    def test_ppd_0
        dotest(
            TestDefinition0,
            "ok")
    end
end

