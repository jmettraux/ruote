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


require 'xmpp4r-simple'

module OpenWFE
  module Extras

    # Common functionality shared by the JabberListener and
    # JabberParticipant implementations in ruote.
    module JabberCommon

      def self.included( base )

        base.instance_eval do
          # JabberID to use
          @jabber_id = nil

          # Jabber password
          @password = nil

          # Jabber resource
          @resource = nil

          # Contacts that are always included in the participants roster
          @contacts = []

          class << self
            attr_accessor :jabber_id, :password, :resource, :contacts
          end

          def jid
            self.jabber_id.nil? ? nil : self.jabber_id + '/' + self.resource
          end
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
          @connection = Jabber::Simple.new( self.class.jid, self.class.password )
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
