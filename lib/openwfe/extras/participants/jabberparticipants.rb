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
# "made in Africa"
#
# Kenneth Kalmer of opensourcery.co.za
#

require 'yaml'
require 'xmpp4r-simple'
require 'json'

module OpenWFE
  module Extras
    
    #
    # Use Jabber (XMPP) during a workflow to communicate with people/processes
    # outside the running engine in an asynchrous fashion.
    #
    class JabberParticipant
      include LocalParticipant
      
      # JabberID to use
      @@jabber_id = nil
      cattr_accessor :jabber_id

      # Jabber password
      @@password = nil
      cattr_accessor :password
      
      # Contacts that are always included in the participants roster
      @@contacts = []
      cattr_accessor :contacts
  
      # Jabber connection
      attr_reader :connection
      
      def initialize( options = {} )
        self.class.jabber_id = options.delete(:jabber_id) if options.has_key?(:jabber_id)
        self.class.password  = options.delete(:password)  if options.has_key?(:password)
        self.class.contacts  = options.delete(:contacts)  if options.has_key?(:contacts)
        
        connect!
        setup_roster!
      end
      
      def consume( workitem )
        ldebug { "consuming workitem" }
        
        if target_jid = workitem.attributes['target_jid']
          
          unless self.connection.subscribed_to?( target_jid )
            self.connection.add( target_jid )
            self.connection.roster.accept_subscription( target_jid )
          end

          busy do
            ldebug { "sending workitem to jid: #{target_jid}" }
            self.connection.deliver( target_jid, encode_workitem( workitem ) )
          end
          
        else
          lerror { "no target_jid in workitem attributes!" }
        end
      end
      
      protected
      
      def connect!
        ldebug { "setting up Jabber connection" }
        
        @connection = Jabber::Simple.new( self.class.jabber_id + '/participant', self.class.password )
        @connection.status( :chat, "JabberParticipant waiting for instructions" )
      end
      
      # Clear all contacts from the roster, and build up the roster again
      def setup_roster!
        ldebug { "cleaning up roster" }
        
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
      
      def encode_workitem( wi )
        YAML.dump( wi )
      end
      
      # Change status to 'busy' while performing a command, and back to 'chat'
      # afterwards
      def busy(&block)
        self.connection.status( :dnd, "Working..." )
        yield
        self.connection.status( :chat, "JabberParticipant waiting for instructions" )
      end
    end
  end
end
