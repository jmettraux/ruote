#--
# Copyright (c) 2008-2009, Kenneth Kalmer, opensourcery.co.za
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Africa. Kenneth Kalmer of opensourcery.co.za
#++


require 'thread'
require 'yaml'

require 'openwfe/util/xml'
require 'openwfe/util/json'
require 'openwfe/service'
require 'openwfe/listeners/listener'
require 'openwfe/extras/misc/jabber_common'

module OpenWFE
  module Extras

    #
    # Use Jabber (XMPP) during a workflow to communicate with people/processes
    # outside the running engine in an asynchrous fashion.
    #
    class JabberListener < Service
      include WorkItemListener
      include Rufus::Schedulable
      include OpenWFE::Extras::JabberCommon

      def initialize( service_name, options )

        @mutex = Mutex.new

        configure_jabber!( options )

        service_name = "#{self.class}::#{self.class.jabber_id}"
        super( service_name, options )

        connect!
        setup_roster!
      end

      def trigger( params )
        @mutex.synchronize do

          ldebug { "trigger()" }

          self.connection.received_messages do |message|
            busy do
              ldebug { "processing message: #{message.inspect}" }
              # the sender must be on our roster

              workitem = decode_workitem( message.body )
              ldebug { "workitem: #{workitem.inspect}" }
              handle_item( workitem )
            end
          end
        end
      end

      def stop
        self.connection.disconnect rescue nil
      end

      protected

      # Complicated guesswork that needs to happen here to detect the format
      def decode_workitem( msg )
        ldebug { "decoding workitem from: #{msg}" }

        # YAML?
        if msg.index('ruby/object:OpenWFE::InFlowWorkItem')
          YAML.load( msg )
        # XML?
        elsif msg =~ /^<.*>$/m
          OpenWFE::Xml.workitem_from_xml( msg )
        # Assume JSON encoded Hash
        else
          hash = OpenWFE::Json.decode(msg)
          OpenWFE.workitem_from_h( hash )
        end
      end
    end
  end
end
