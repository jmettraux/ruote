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
require 'xmpp4r-simple'

require 'openwfe/util/xml'
require 'openwfe/util/json'
require 'openwfe/service'
require 'openwfe/listeners/listener'


module OpenWFE
  module Extras

    #
    # Use Jabber (XMPP) during a workflow to communicate with people/processes
    # outside the running engine in an asynchrous fashion.
    #
    class JabberListener < Service
      include WorkItemListener
      include Rufus::Schedulable

      # JabberID to use
      @@jabber_id = nil
      cattr_accessor :jabber_id

      # Jabber password
      @@password = nil
      cattr_accessor :password

      # Jabber resource
      @@resource = 'listener'
      cattr_accessor :resource

      # Contacts that are always included in the participants roster
      @@contacts = []
      cattr_accessor :contacts

      # Jabber connection
      attr_reader :connection

      def initialize( service_name, options )

        @mutex = Mutex.new

        self.class.jabber_id = options.delete( :jabber_id )
        self.class.password = options.delete( :password )
        self.class.contacts = options.delete( :contacts )
        self.class.resource = options.delete( :resource )

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

      def connect!
        jid = self.class.jabber_id + '/' + self.class.resource
        @connection = Jabber::Simple.new( jid, self.class.password )
        @connection.status( :chat, "JabberListener waiting for instructions" )
      end

      # Clear all contacts from the roster, and build up the roster again
      def setup_roster!
        # Clean the roster
        self.connection.roster.items.each_pair do |jid, roster_item|
          jid = jid.strip.to_s
          unless self.class.contacts.include?( jid )
            self.connection.remove( jid )
          end
        end

        # Add missing contacts
        self.class.contacts.each do |contact|
          unless self.connection.subscribed_to?( contact )
            self.connection.add( contact )
            self.connection.roster.accept_subscription( contact )
          end
        end
      end

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

      # Change status to 'busy' while performing a command, and back to 'chat'
      # afterwards
      def busy( &block )
        self.connection.status( :dnd, "Working..." )
        yield
        self.connection.status( :chat, "JabberListener waiting for instructions" )
      end
    end
  end
end
