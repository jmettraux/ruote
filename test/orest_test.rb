
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#

require 'rubygems'

require 'test/unit'
require 'fileutils'
require 'webrick'

require 'rutest_utils'
require 'openwfe/orest/worklistclient'
require 'openwfe/engine/engine'
require 'openwfe/worklist/oldrest'
require 'openwfe/worklist/storelocks'
require 'openwfe/worklist/storeparticipant'
require 'openwfe/worklist/worklist'


class OldRestTest < Test::Unit::TestCase

    def setup

        #$DEBUG = true

        @engine = OpenWFE::Engine.new(
            { :definition_in_launchitem_allowed => true })

        FileUtils.mkdir "logs" unless File.exist?("logs")

        logger = WEBrick::Log.new "logs/orest_test.webrick.log"
        logger.level = WEBrick::Log::DEBUG

        #
        # preparing a worklist

        @worklist = OpenWFE::Worklist.new(
            @engine.application_context,
            :auth_system => { "foo" => "bar" })
            #:launchables => {})

        @worklist.add_store(
            "alpha", 
            "alpha", 
            OpenWFE::StoreWithLocks.new(OpenWFE::HashParticipant))
        @worklist.add_store(
            "bravo", 
            "bravo", 
            OpenWFE::StoreWithLocks.new(OpenWFE::HashParticipant))

        #
        # registering the worklist (behind two participants)
        
        @engine.register_participant :alpha, @worklist
        @engine.register_participant :bravo, @worklist

        #
        # preparing and starting the webserver
        # (it's a REST interface after all)

        @server = WEBrick::HTTPServer.new(
            :Port => 5080,
            :BindAddress => "0.0.0.0",
            :Logger => logger,
            :AccessLog => [[ 
                File.open("logs/orest_test.access.log", "w"), 
                WEBrick::AccessLog::COMMON_LOG_FORMAT ]])

        @server.mount(
            "/worklist", 
            OpenWFE::OldRestWorklistServlet, 
            :AuthSystem => @worklist,
            :Worklist => @worklist)

        Thread.new do
            @server.start
        end
    end

    def get_servlet
        servlet_class = @server.search_servlet("/worklist")[0]
        servlet_class.get_instance(@server, {})
    end

    def teardown
        @server.shutdown
        @engine.stop
    end


    def test_0

        #sleep 0.1

        #
        # just checking that we get bounced in case of wrong credentials
        
        assert_raise RuntimeError do
            client = OpenWFE::WorklistClient.new(
                "http://localhost:5080/worklist", "foo", "foo")
        end

        client = OpenWFE::WorklistClient.new(
            "http://localhost:5080/worklist", "foo", "bar")

        assert client.session_id > 0

        assert_equal get_servlet.instance_variable_get(:@sessions).size, 1

        #
        # are there two stores in this worklist ?

        l = client.list_stores

        assert_equal l.size, 2

        store = l[0]

        assert_equal store.name, "alpha"

        #
        # playing with a mock workitem

        assert_raise RuntimeError do
            client.get_headers "nada"
        end

        actual_store = @worklist.get_store "alpha"
        actual_store.consume(new_workitem())

        headers = client.get_headers "alpha"
        #headers = client.get_headers "Store.alpha"

        assert_equal 1, headers.length
        assert_equal "surf", headers[0].attributes["nada"]
        assert_equal "surf", headers[0].nada

        #
        # launching a new process...

        li = OpenWFE::LaunchItem.new('''
<process-definition name="orest" revision="1">
    <sequence>
        <participant ref="alpha" />
        <participant ref="bravo" />
    </sequence>
</process-definition>
        '''.strip)
        li.myfield = "myvalue"

        fei = client.launch_flow "any", li

        assert_kind_of OpenWFE::FlowExpressionId, fei

        sleep 0.7

        headers = client.get_headers "alpha"

        #require 'pp'; pp headers

        assert_equal headers.size, 2

        # yes, the workitem of our newly launched process has arrived...

        fei.expression_id = "0.0.0"
        fei.expression_name = "participant"

        wi = client.get_workitem "alpha", fei

        assert_equal wi.myfield, "myvalue"

        wi = client.get_and_lock_workitem "alpha", fei

        # got the workitem and made sure others can't modify / forward it

        assert_equal wi.myfield, "myvalue"

        headers = client.get_headers "alpha"

        h = nil
        headers.each do |hh|
            if hh.locked
                h = hh
                break
            end
        end

        assert_equal h.fei, fei

        feis = client.find_flow_instance "alpha", fei.wfid

        assert_equal feis.size, 1

        # releasing the fish...

        client.release_workitem wi

        headers = client.get_headers "alpha"

        assert (not (headers[0].locked or headers[1].locked))

        assert_raise RuntimeError do
            client.save_workitem wi
        end

        # catching it again

        wi = client.get_and_lock_workitem "alpha", fei

        wi.got_forwarded = true

        client.forward_workitem wi

        headers = client.get_headers "alpha"

        assert_equal headers.size, 1

        assert_nil headers[0].attributes['got_forwarded']
            #
            # still our old initial workitem, inserted manually

        sleep 0.500

        headers = client.get_headers "bravo"

        assert_equal headers.size, 1

        assert_equal headers[0].got_forwarded, true

        #
        # done

        client.close

        assert_equal get_servlet.instance_variable_get(:@sessions).size, 0
    end

    protected

        def new_workitem ()
            wi = OpenWFE::InFlowWorkItem.new
            wi.fei = new_fei()
            wi.attributes = { "nada" => "surf" }
            wi
        end

end

