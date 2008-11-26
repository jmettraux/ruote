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

require 'openwfe/util/xml'
require 'openwfe/util/json'

if defined?( ActiveSupport )
  # Fix broken ActiveSupport Time#to_json notation
  class Time
    def to_json(*a)
      if ActiveSupport.use_standard_json_time_format
        xmlschema.inspect
      else
        %("#{strftime("%Y/%m/%d %H:%M:%S")} #{formatted_offset(false)}")
      end
    end
  end
end

module OpenWFE
  module Extras
    
    #
    # Use Jabber (XMPP) during a workflow to communicate with people/processes
    # outside the running engine in an asynchrous fashion.
    # 
    # The JabberParticipant will send a JSON encoded InFlowWorkItem to a Jabber 
    # ID specified in the 'target_id' attribute of the workitem's attributes.
    # To change the format sent, use the 'message_format' attribute of the
    # workitem, and set it to either 'XML' or 'YAML' (defaults to 'JSON').
    # 
    # You can specify the JID, password and JID resource names on class level
    # or by passing the :jabber_id, :password, or :resource keys to the 
    # construct. By default the 'participant' resoure is used.
    # 
    # The roster management is currently dynamic as well. It will clear the
    # roster when it starts, except for a hard coded list of contacts. As
    # messages are sent out the roster will be populated with those JID's,
    # making sure that the listener will respond to replies.
    # 
    # A small example:
    # 
    #   engine.register_participant( 
    #     :jabber,
    #     OpenWFE::Extras::JabberParticipant.new( :jabber_id => 'ruote@devbox', :password => 'secret', :contacts => ['kenneth@devbox'] )
    #   )
    #
    class JabberParticipant
      include LocalParticipant
      
      # JabberID to use
      @@jabber_id = nil
      cattr_accessor :jabber_id

      # Jabber password
      @@password = nil
      cattr_accessor :password
      
      # Jabber resource
      @@resource = 'participant'
      cattr_accessor :resource
      
      # Contacts that are always included in the participants roster
      @@contacts = []
      cattr_accessor :contacts
  
      # Jabber connection
      attr_reader :connection
      
      def initialize( options = {} )
        self.class.jabber_id = options.delete(:jabber_id) if options.has_key?(:jabber_id)
        self.class.password  = options.delete(:password)  if options.has_key?(:password)
        self.class.contacts  = options.delete(:contacts)  if options.has_key?(:contacts)
        self.class.resource  = options.delete(:resource)  if options.has_key?(:resource)
        
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
          
          # Sensible defaults
          workitem.attributes.reverse_merge!({ 'format' => 'JSON' })

          ldebug { "sending workitem to jid: #{target_jid}" }
          self.connection.deliver( 
            target_jid, 
            encode_workitem( workitem, workitem.attributes['format'] ) 
          )
          
        else
          lerror { "no target_jid in workitem attributes!" }
        end
      end
      
      protected
      
      def connect!
        ldebug { "setting up Jabber connection" }
        
        jid = self.class.jabber_id + '/' + self.class.resource
        @connection = Jabber::Simple.new( jid, self.class.password )
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
      
      def encode_workitem( wi, format = 'JSON' )
        if format.downcase == 'xml'
          OpenWFE::Xml.workitem_to_xml( wi )
        elsif format.downcase == 'yaml'
          YAML.dump( wi )
        else
          OpenWFE::Json.workitem_to_h( wi ).to_json
        end
        
      end
      
    end
  end
end
