#
#--
# Copyright (c) 2007-2009, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'yaml'
require 'socket'

require 'openwfe/utils'
require 'openwfe/service'
require 'openwfe/workitem'
require 'openwfe/rudefinitions'
require 'openwfe/orest/xmlcodec'
require 'openwfe/listeners/listener'


#
# some base listener implementations
#
module OpenWFE

  #
  # Listens for workitems on a socket.
  #
  # Workitems can be instances of InFlowWorkItem or LaunchItem.
  #
  # By default, listens on port 7007.
  #
  #   require 'openwfe/listeners/socketlisteners'
  #
  #   engine.add_workitem_listener(OpenWFE::SocketListener)
  #
  # But you can be more specific :
  #
  #   engine.add_workitem_listener(
  #     OpenWFE::SocketListener.new(
  #       "sl_whatever_name",
  #       engine.application_context,
  #       "target.host.xx",
  #       7707)
  #
  class SocketListener < Service
    include WorkItemListener

    attr_reader :server, :thread

    def initialize (service_name, application_context, port=nil, iface=nil)

      super(service_name, application_context)

      #iface ||= "127.0.0.1"
        # not necessary

      port ||= 7007

      @server = TCPServer.new(iface, port)

      @thread = Thread.new do
        begin
          listen
        rescue Exception => e
          lerror { "listening socket died\n#{e}" }
        end
      end
      @thread[:name] = @service_name
    end

    #
    # Stops this socket listener (shuts down its socket)
    #
    def stop

      @thread.raise "shutdown"

      begin
        @server.close
      rescue Exception => e
        ldebug { "stop() exc : #{e.to_s}" }
      end
      #begin
      #  @server.shutdown
      #rescue Exception => e
      #  ldebug { "stop() exc : #{e.to_s}" }
      #end

      linfo { "stop() shut socket down" }
    end

    #
    # This base implementation is capable of decoding XML workitems
    # and YAML workitems.
    #
    def decode_workitem (data)

      return nil if not data or data.length < 4

      if data[0, 1] == "<"
        #
        # seems like XML

        OpenWFE::XmlCodec::decode(data)

      elsif data[0, 3] == "---"
        #
        # must be YAML

        YAML.load(data)

      else
        #
        # perhaps OpenWFEja style header + workitem

        data = pop_line(data)
        data = pop_line(data)

        decode_workitem(data)
      end
    end

    #
    # Simply pipes back the result of get_engine.reply(wi) on the
    # socket.
    #
    def reply_to_socket (socket, result)

      socket.puts result.to_s
      socket.puts
      socket.close_write

      #ldebug { "reply_to_socket() result is >#{result}<" }
    end

    #
    # The base implementation allows returns true.
    #
    # An override of this method might check the origin of the socket
    # and maybe only allow a certain range of hosts...
    #
    def is_allowed? (socket)

      true
    end

    protected

      #
      # Where the socket waiting loop is...
      #
      def listen

        linfo { "listen() listening on #{@server.addr.join('  ')}" }

        loop do

          socket = nil

          begin
            socket = @server.accept
          rescue Exception => e
            linfo { "listen() shut down '#{e}'" }
          end

          return unless socket

          t = Thread.new do
            begin
              handle_socket(socket) if socket and is_allowed?(socket)
            rescue Exception => e
              lerror { "error while handling socket\n#{e}" }
            end
          end
          t[:name] = @service_name
        end
      end

      #
      # The bulk work of handling a connection is done here. The
      # incoming workitem is piped to the engine, then the result
      # it written back a string on the socket which then gets closed.
      #
      def handle_socket (socket)

        ldebug do
          "handle_socket() "+
          "connection from #{socket.peeraddr.join('  ')}"
        end

        data = ""
        loop do
          s = socket.gets
          break unless s
          data += s
        end

        wi = decode_workitem(data)

        if not wi

          ldebug do
            "handle_socket() "+
            ">>>#{data}<<< doesn't contain a workitem"
          end
          socket.close
          return

        else

          ldebug do
            "handle_socket() "+
            "received something of class #{wi.class}"
          end
        end

        result = nil

        begin

          #result = get_engine.reply(wi)
          #result = handle_item(wi)
          handle_item wi

          result = "<ok-reply/>"

          ldebug { "handle_socket() result is >>#{result}<<" }

        rescue Exception => e

          result = "ERROR\n\n"
          result << OpenWFE::exception_to_s(e)

          ldebug { "handle_socket() error reply :\n" + result }
        end

        reply_to_socket(socket, result)

        socket.close
      end

      def pop_line (s)

        i = s.index("\n")
        return s unless i
        s[i+1..-1]
      end
  end

end

