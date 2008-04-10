
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'yaml'
require 'socket'

require 'openwfe/def'
require 'openwfe/listeners/socketlisteners'
require 'openwfe/participants/socketparticipants'

require 'flowtestbase'


class FlowTest30 < Test::Unit::TestCase
    include FlowTestBase

    #def teardown
    #end

    #def setup
    #end


    #
    # TEST 0

    class TestDefinition0 < ProcessDefinition
        _print "${f:message}"
    end

    def test_0

        log_level_to_debug

        sl = OpenWFE::SocketListener.new(
            "socket_listener", @engine.application_context, 7008)

        @engine.add_workitem_listener(sl)

        li = LaunchItem.new(TestDefinition0.do_make)
        li.message = "ok"
        s = YAML.dump(li)

        socket = TCPSocket.new("localhost", 7008)
        socket.puts(s)
        socket.close_write

        reply = socket.gets
        socket.close

        #puts ">>>#{reply}<<<"
        assert (reply.match "^.fei .*0.$")

        sleep 0.200

        trace = @tracer.to_s

        assert_equal trace, "ok"
    end


    #
    # TEST 1

    def test_sl_1

        @engine.add_workitem_listener(OpenWFE::SocketListener)

        li = LaunchItem.new(TestDefinition0.do_make)
        li.message = "ok1"
        s = YAML.dump(li)

        socket = TCPSocket.new("localhost", 7007)
        socket.puts(s)
        socket.puts
        socket.close_write

        reply = socket.gets
        socket.close

        #puts ">>>#{reply}<<<"
        assert (reply.match "^.fei .*0.$")

        sleep 0.100

        trace = @tracer.to_s

        assert_equal trace, "ok1"
    end


    #
    # TEST 2

    def test_sl_2

        @engine.add_workitem_listener(OpenWFE::SocketListener)

        li = LaunchItem.new(TestDefinition0.do_make)
        li.message = "ok2"
        s = YAML.dump(li)

        socket = TCPSocket.new("localhost", 7007)
        socket.puts("XmlEncoder 777")
        socket.puts
        socket.puts(s)
        socket.puts
        socket.close_write

        assert (not socket.closed?)

        sleep 0.100

        reply = socket.gets
        socket.close

        #puts ">>>#{reply}<<<"
        assert_not_nil reply.match("^.fei .*0.$")

        sleep 0.100

        trace = @tracer.to_s

        assert_equal trace, "ok2"
    end


    #
    # TEST 3

    def test_sl_3

        @engine.add_workitem_listener(OpenWFE::SocketListener)

        li = LaunchItem.new(TestDefinition0.do_make)

        trace = ""

        1.upto(4) do |i|
            trace << "#{i}\n"
            li.message = i
            send_li(li)
        end
        1.upto(3) do |i|
            trace << "#{i}\n"
            li.message = i
            send_li_sp(li)
        end
        1.upto(3) do |i|
            trace << "#{i}\n"
            li.message = i
            send_li_xsp(li)
        end
        1.upto(3) do |i|
            trace << "#{i}\n"
            li.message = i
            send_li_ssp(li)
        end
        1.upto(3) do |i|
            trace << "#{i}\n"
            li.message = i
            send_li_sxsp(li)
        end

        trace = trace.strip

        sleep 0.300

        assert_equal @tracer.to_s, trace
    end

    def send_li (li)
        socket = TCPSocket.new("localhost", 7007)
        socket.puts(YAML.dump(li))
        socket.puts
        socket.close_write
        reply = socket.gets
        socket.close
    end
    def send_li_sp (li)
        sp = OpenWFE::SocketParticipant.new("localhost", 7007)
        sp.consume(li)
    end
    def send_li_xsp (li)
        sp = OpenWFE::XmlSocketParticipant.new("localhost", 7007)
        sp.consume(li)
    end

    def send_li_ssp (li)
        OpenWFE::SocketParticipant.dispatch("localhost", 7007, li)
    end

    def send_li_sxsp (li)
        OpenWFE::XmlSocketParticipant.dispatch("localhost", 7007, li)
    end
end

