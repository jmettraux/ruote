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
            _print "${f:hcode}"
            _print "${f:hdata}"

            set :f => :hdata, :val => "nada"
            hpost "http://localhost:7777/items"
            _print "${f:hcode}"
            _print "${f:hheaders.location}"

            hget "${f:hheaders.location}"
            _print "${f:hcode}"
            _print "${f:hdata}"
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
            hget "http://localhost:7777/lost", :htimeout => 1
            _print "${f:hcode}"
        end
    end

    def test_1

        #log_level_to_debug

        dotest Test1, "-1"
    end

    #
    # TEST 2

    class Test2 < OpenWFE::ProcessDefinition
        sequence do
            hpoll "http://localhost:7777/items", :until => "${f:hcode} == 200"
            _print "${f:hcode}"
        end
    end

    def test_2

        #log_level_to_debug

        dotest Test2, "200"
    end

end

