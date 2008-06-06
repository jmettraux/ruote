#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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
require 'timeout'

require 'openwfe/orest/xmlcodec'
require 'openwfe/participants/participant'


module OpenWFE

  #
  # This participant implementation dispatches workitems over TCP sockets.
  # By default the workitem are dumped as YAML strings, but you can override
  # the encode_workitem(wi) method.
  #
  # A small example :
  #
  #   require 'openwfe/particpants/socketparticipants'
  #
  #   sp = OpenWFE::SocketParticipant.new("target.host.xx", 7007)
  #
  #   engine.register_participant("Alfred", sp)
  #
  class SocketParticipant

    attr_accessor :host, :port

    #
    # The constructor
    #
    def initialize (host, port)

      @host = host
      @port = port
    end

    #
    # The method called by the engine for each incoming workitem.
    # Will dispatch the workitem over a TCP connection.
    #
    def consume (workitem)

      dispatch(workitem)
    end

    def dispatch (workitem)

      socket = TCPSocket.new(@host, @port)
      socket.puts encode_workitem(workitem)
      socket.puts
      socket.close_write

      #print "\n__socket.closed? #{socket.closed?}"

      reply = fetch_reply(socket)

      socket.close

      decode_reply(reply)
    end

    #
    # A 'static' method for dispatching workitems, you can use it
    # directly, without instantiating the SocketParticipant :
    #
    #   require 'openwfe/participants/socketparticipants'
    #
    #   SocketParticipant.dispatch("127.0.0.1", 7007, workitem)
    #
    def SocketParticipant.dispatch (host, port, workitem)

      SocketParticipant.new(host, port).dispatch(workitem)
    end

    protected

      #
      # By default, uses YAML to serialize the workitem
      # (of course you can override this method).
      #
      def encode_workitem (wi)
        YAML.dump(wi)
      end

      #
      # By default, will just return the reply without touching it
      #
      def decode_reply (r)
        r
      end

      #
      # The code that waits for the reply from the server, nicely
      # wrapped inside a timeout and a rescue block.
      #
      def fetch_reply (socket)

        reply = ""

        begin

          timeout(7) do
            while true
              r = socket.gets
              break unless r
              reply << r
            end
          end

        rescue Exception => e
          puts e
          raise "timeout while waiting for reply"
        end

        reply
      end
  end

  #
  # This extension of of SocketParticipant can be used to dispatch
  # workitems towards an OpenWFEja instance, but OpenWFEru's SocketListener
  # understands XML workitems as well.
  #
  class XmlSocketParticipant < SocketParticipant

    #def initialize (host, port)
    #  super
    #end

    #
    # A 'static' method for dispatching workitems, you can use it
    # directly, without instantiating the SocketParticipant :
    #
    #   require 'openwfe/participants/socketparticipants'
    #
    #   SocketParticipant.dispatch("127.0.0.1", 7007, workitem)
    #
    def XmlSocketParticipant.dispatch (host, port, workitem)

      XmlSocketParticipant.new(host, port).consume(workitem)
    end

    protected

      #
      # This implementation encodes the workitem as an XML document.
      # This is compatible with OpenWFEja.
      #
      def encode_workitem (wi)

        sxml = OpenWFE::XmlCodec::encode(wi)

        s = "xmlCoder #{sxml.length}\n"
        s << "\n"
        s << sxml
        s << "\n"
        s << "\n"
        s
      end
  end

end

