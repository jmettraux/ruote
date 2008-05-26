#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon May 26 14:00:48 JST 2008
#

require 'rubygems'

require 'flowtestbase'

require 'openwfe/def'

require '~/rufus/rufus-verbs/test/items'


class FlowTest88 < Test::Unit::TestCase
    include FlowTestBase

    def setup
        super
        @server = ItemServer.new
        @server.start
    end
    def teardown
        super
        @server.shutdown
    end
        #
        # using the rufus-verbs 'items' restful server for testing

    #
    # TEST 0

    class Test0 < OpenWFE::ProcessDefinition
        sequence do

            hget "http://localhost:7777/items"
            _print "${f:rcode}"
            _print "${f:rbody}"

            set :f => :hdata, :val => "nada"
            hpost "http://localhost:7777/items"
            _print "${f:rcode}"
            _print "${f:rheaders.location}"

            hget "${f:rheaders.location}"
            _print "${f:rcode}"
            _print "${f:rbody}"
        end
    end

    def test_0

        dotest(
            Test0,
            [
                200, "{}\n",
                201, "http://localhost:7777/items/0",
                200, '"nada"'
            ].collect { |e| e.to_s }.join("\n"))
    end

    #
    # TEST 1

    class Test1 < OpenWFE::ProcessDefinition
        sequence do
            hget "http://localhost:7777/lost", :timeout => 1
            _print "${f:rcode}"
        end
    end

    def test_1

        dotest Test1, "-1"
    end

end

