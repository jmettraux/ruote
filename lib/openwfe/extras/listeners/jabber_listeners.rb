#
#--
# Copyright (c) 2008-2009, Kenneth Kalmer, opensourcery.co.za
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
# "made in Africa"
#
# Kenneth Kalmer of opensourcery.co.za
#

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
          hash = defined?(ActiveSupport::JSON) ? ActiveSupport::JSON.decode(msg) : JSON.parse(msg)
          OpenWFE.workitem_from_h( hash )
        end
      end
    end
  end
end
