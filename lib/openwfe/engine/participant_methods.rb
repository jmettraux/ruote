#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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
# Made in Japan.
#++


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
    #   engine.register_participant "user-.*", HashParticipant
    #
    # or
    #
    #   require 'openwfe/participants/mail_participants'
    #
    #   engine.register_participant(
    #     'user-toto',
    #     OpenWFE::MailParticipant.new(
    #       :smtp_server => "mailhost.ourcompany.co.jp",
    #       :smtp_port => 25,
    #       :from_address => "bpms@our.ourcompany.co.jp"
    #     ) { |workitem|
    #       s = ""
    #       s << "Dear #{workitem.name},\n"
    #       s << "\n"
    #       s << "it's #{Time.new.to_s} and you've got mail"
    #       s
    #     })
    #
    # or
    #
    #   engine.register_participant "user-.*" do |wi|
    #     puts "participant '#{wi.participant_name}' received a workitem"
    #     #
    #     # and did nothing with it
    #     # as a block participant implicitely returns the workitem
    #     # to the engine
    #   end
    #
    # Returns the participant instance.
    #
    # The participant parameter can be set to hash like in
    #
    #   engine.register_participant(
    #     "alpha",
    #     { :participant => HashParticipant, :position => :first })
    #
    # or
    #
    #   engine.register_participant("alpha", :position => :first) do
    #     puts "first !"
    #   end
    #
    # There are some times where you have to position a participant first
    # (especially with the regex technique).
    #
    # some participants have an 'initialize' method whose unique parameter
    # is a option hash
    #
    #   engine.register_participant(
    #     "investors",
    #     InvestorParticipant,
    #     { :money => 'lots of it', :clues => 'none' })
    #
    def register_participant (regex, participant=nil, options={}, &block)

      params = participant.class == Hash ?
        participant : { :participant => participant }

      params = params.merge(options)

      get_participant_map.register_participant(regex, params, &block)
    end

    #
    # Given a participant name, returns the participant in charge
    # of handling workitems for that name.
    # May be useful in some embedded contexts.
    #
    def get_participant (participant_name)

      get_participant_map.lookup_participant(participant_name)
    end

    #
    # Removes the first participant matching the given name from the
    # participant map kept by the engine.
    #
    # If 'participant_name' is an integer, will remove the participant
    # at that position in the participant list.
    #
    def unregister_participant (participant_name)

      get_participant_map.unregister_participant(participant_name)
    end

    #
    # Returns the list of participants registered in the engine.
    # In the resolution order.
    #
    # Returns a list of [ regex, participant ] pairs.
    #
    def participants

      get_participant_map.participants
    end
    #alias :list_participants :participants
      # deprecated
  end

end

