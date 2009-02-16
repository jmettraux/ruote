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

require 'yaml'

require 'openwfe/util/xml'
require 'openwfe/util/json'

require 'openwfe/extras/misc/jabber_common'

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
    # Configuration example:
    #
    #   engine.register_participant(
    #     :jabber,
    #     OpenWFE::Extras::JabberParticipant.new( :jabber_id => 'ruote@devbox', :password => 'secret', :contacts => ['kenneth@devbox'] )
    #   )
    #
    # Process example:
    #
    #   class JabberProcess < OpenWFE::ProcessDefinition
    #     sequence do
    #       jabber :wait_for_reply => true
    #     end
    #
    #     set :f => 'target_jid', :val => 'kenneth.kalmer@gmail.com'
    #   end
    #
    # Passing the 'wait_for_reply' parameter to the participant
    # prevents it from replying to the engine, and thus expects the
    # JabberListener to pick up the reply and let the process
    # continue. By default the JabberParticipant will send the message
    # and reply to the engine, letting the workflow continue.
    class JabberParticipant
      include LocalParticipant
      include OpenWFE::Extras::JabberCommon

      def initialize( options = {} )
        configure_jabber!( options )
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

          # Message or workitem?
          if message = ( workitem.attributes['message'] || workitem.params['message'] )
            self.connection.deliver( target_jid, message )
            
          else
            # Sensible defaults
            workitem.attributes.reverse_merge!({ 'format' => 'JSON' })

            ldebug { "sending workitem to jid: #{target_jid}" }
            self.connection.deliver(
              target_jid,
              encode_workitem( workitem, workitem.attributes['format'] )
            )
          end
        else
          lerror { "no target_jid in workitem attributes!" }
        end
        
        unless workitem.params['wait-for-reply'] == true
          reply_to_engine( workitem )
        end
      end

      protected

      def encode_workitem( wi, format = 'JSON' )
        if format.downcase == 'xml'
           wi.to_xml
        elsif format.downcase == 'yaml'
          YAML.dump( wi )
        else
          wi.to_h.to_json
        end

      end

    end
  end
end
