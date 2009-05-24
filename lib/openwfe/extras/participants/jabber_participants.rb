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
            ldebug { "sending workitem to jid: #{target_jid}" }
            self.connection.deliver(
              target_jid,
              encode_workitem( workitem )
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

      # Encode (and extend) the workitem as JSON
      def encode_workitem( wi )
        h = wi.to_h
        h['sender_jid'] = self.class.jid
        h['reply_jid'] = JabberListener.jid

        OpenWFE::Json.encode( h )
      end

    end
  end
end
