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

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

module OpenWFE

    #
    # The methods of the engine about participants (register, unregister,
    # lookup, ...)
    #
    module ParticipantMethods

        #
        # Registers a participant in this [embedded] engine.
        # This method is a shortcut to the ParticipantMap method
        # with the same name.
        #
        #    engine.register_participant "user-.*", HashParticipant
        #
        # or
        #
        #    engine.register_participant "user-.*" do |wi|
        #        puts "participant '#{wi.participant_name}' received a workitem"
        #        #
        #        # and did nothing with it
        #        # as a block participant implicitely returns the workitem
        #        # to the engine
        #    end
        #
        # Returns the participant instance.
        #
        # The participant parameter can be set to hash like in
        #
        #     engine.register_participant(
        #         "alpha", 
        #         { :participant => HashParticipant, :position => :first })
        #
        # or
        #
        #     engine.register_participant("alpha", :position => :first) do
        #         puts "first !"
        #     end
        #
        # There are some times where you have to position a participant first
        # (especially with the regex technique).
        #
        # see ParticipantMap#register_participant
        #
        def register_participant (regex, participant=nil, &block)

            #get_participant_map.register_participant(
            #    regex, participant, &block)

            params = if participant.class == Hash
                participant
            else
                { :participant => participant }
            end

            get_participant_map.register_participant regex, params, &block
        end

        #
        # Given a participant name, returns the participant in charge
        # of handling workitems for that name.
        # May be useful in some embedded contexts.
        #
        def get_participant (participant_name)

            get_participant_map.lookup_participant participant_name
        end

        #
        # Removes the first participant matching the given name from the
        # participant map kept by the engine.
        #
        # If 'participant_name' is an integer, will remove the participant
        # at that position in the participant list.
        #
        def unregister_participant (participant_name)

            get_participant_map.unregister_participant participant_name
        end

        #
        # Returns the list of participants registered in the engine.
        # In the resolution order.
        #
        # Returns a list of [ regex, participant ] pairs.
        #
        def list_participants

            get_participant_map.participants
        end
    end

end

