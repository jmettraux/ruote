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
    # TEST 0

    class Test0 < OpenWFE::ProcessDefinition
        sequence do

            get "http://localhost:7777/items"
            _print "${f:rcode}"
            _print "${f:rbody}"

            set :f => :body, :val => "nada"
            post "http://localhost:7777/items"
            _print "${f:rcode}"
            _print "${f:rheaders.location}"

            get :uri => "${f:rheaders.location}"
            _print "${f:rcode}"
            #_print "${f:rbody}"
        end
    end

    def test_0

        dotest(
            Test0,
            [
                200, "{}\n", 201, "http://localhost:7777/items/0", 200
            ].collect { |e| e.to_s }.join("\n"))
    end

end

