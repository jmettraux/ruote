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

require 'activesupport'
require 'xmpp4r-simple'

module OpenWFE
  module Extras

    # Common functionality shared by the JabberListener and
    # JabberParticipant implementations in ruote.
    module JabberCommon

      def self.included( base )

        base.instance_eval do
          # JabberID to use
          @@jabber_id = nil
          cattr_accessor :jabber_id

          # Jabber password
          @@password = nil
          cattr_accessor :password

          # Jabber resource
          @@resource = nil
          cattr_accessor :resource

          # Contacts that are always included in the participants roster
          @@contacts = []
          cattr_accessor :contacts
        end
        
      end
      
      # Configures this class from the provided options hash. Looking
      # for (and removes) the following keys from the hash:
      #
      #   * :connection => Already configured xmpp4r-simple instance
      #   * :jabber_id  => Jabber ID to use
      #   * :password   => Password for the JID
      #   * :resource   => (Optional) Name of the resource
      #   * :contacts   => (Array) List of contacts to use
      #
      # If a connection is provided, the :jabber_id, :password,
      # :resource and :contact keys are ignored
      def configure_jabber!( options )
        unless @connection = options.delete(:connection)
          self.class.jabber_id = options.delete(:jabber_id)
          self.class.password  = options.delete(:password)
          self.class.resource  = options.delete(:resource) || 'ruote'
          self.class.contacts  = options.delete(:contacts) || []
        end
      end

      def connection
        @connection.reconnect unless @connection.connected?
        @connection
      end

      protected

      def connect!
        if @connection.nil?
          jid = self.class.jabber_id + '/' + self.class.resource
          @connection = Jabber::Simple.new( jid, self.class.password )
          @connection.status( :chat, "#{self.class} waiting for instructions" )
        end
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
