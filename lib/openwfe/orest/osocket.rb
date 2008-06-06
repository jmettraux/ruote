#
#--
# Copyright (c) 2006-2008, John Mettraux, OpenWFE.org
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

require 'socket'

require 'openwfe/orest/xmlcodec'


module OpenWFE

  #
  # This code was blogged about at
  # http://jmettraux.wordpress.com/2006/06/01/openwfe-ruby/
  #
  class OldSocketListener < TCPServer

  #
  # starts to listen on a given interface (IP) and port
  #
  def initialize (iface, port)
    super(iface, port)
  end

  def listen ()
    while (session = accept())
    #
    # how does it scale ?

    s = session.gets

    if s[0..8] != 'xmlCoder '
      session.close
      break
    end

    l = s[9..-1].to_i

    s = session.gets
      #
      # skipping the empty line between the
      # header and the actual workitem

    sXml = ''

    while sXml.length < l
      s = session.gets
      sXml = "#{sXml}#{s}"
    end

    session.print "<ok-reply/>"
    session.close

    yield OpenWFE.xml_decode(xml.root)
    end
  end
  end

  #
  # Dispatches a workitem over TCP, the workitem will be
  # encoded with XML
  # The default encode_method is
  #
  def OpenWFE.dispatch_workitem (host, port, workitem)

  #sXml = OpenWFE.xml_encode(workitem)
  sXml = OpenWFE::XmlCodec::encode workitem

  socket = TCPSocket.new(host, port)
  socket.puts "xmlCoder #{sXml.length}"
  socket.puts
  socket.puts sXml
  socket.puts
  socket.close_write

  reply = socket.gets

  #reply = reply + socket.gets
    #
    # a bit ridiculous, but it works
    # socket.close_write fixed it

  socket.close

  #puts "dispatch() reply is >#{reply}<"
  end

end


#
# some test code

#sl = OpenWFE::OldSocketListener.new('127.0.0.1', 7010)
#
#puts "..ready.."
#
#sl.listen do |workitem|
#
#  #puts workitem
#  #next
#
#  puts workitem.flow_expression_id
#  puts "...history length : #{workitem.history.length}"
#
#  #puts workitem.history
#  workitem.history.each do |hi|
#  puts ".....hi = '#{hi.text}' #{hi.date}"
#  end
#
#  #hi = OpenWFE::HistoryItem.new
#  #hi.author = 'osocket.rb'
#  #workitem.history.push(hi)
#
#  workitem.attributes['ruby?'] = 'yes'
#
#  OpenWFE.dispatch_workitem('127.0.0.1', 7007, workitem)
#end

