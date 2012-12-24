#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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


module Ruote::Exp

  #
  # This expressions lets one register participants directly from a process
  # definition.
  #
  #   pdef = Ruote.define do
  #
  #     registerp 'alpha', :class => 'MyParticipant', :target => 'mail'
  #       # register participant named 'alpha' with the given class
  #       # and some attributes
  #
  #     registerp /^user_.+/, :class => 'MyParticipant'
  #     registerp :regex => '^user_.+', :class => 'MyParticipant'
  #       # register participant with a given regular expression
  #
  #     registerp 'admin', :class => 'MyParticipant', :position => -2
  #       # register participant 'admin' as second to last in participant list
  #   end
  #
  # Participant info can be given as attributes to the expression (see code
  # above) or via the workitem.
  #
  #   pdef = Ruote.define do
  #
  #     registerp :participant => 'participant'
  #       # participant info is found in the field 'participant'
  #
  #     registerp :participants => 'participants'
  #       # an array of participant info is found in the field 'participants'
  #   end
  #
  # The expression 'unregisterp' can be used to remove participants from the
  # participant list.
  #
  class RegisterpExpression < FlowExpression

    names :registerp

    def apply

      registerp_allowed?

      if pa = attribute('participant')

        register_participant(h.applied_workitem['fields'][pa])

      elsif pas = attribute('participants')

        h.applied_workitem['fields'][pas].each do |part|
          register_participant(part)
        end

      else

        register_participant(attributes)
      end

      reply_to_parent(h.applied_workitem)
    end

    def reply(workitem)

      # never called
    end

    protected

    def registerp_allowed?

      raise ArgumentError.new(
        "'registerp_allowed' is set to false, cannot [un]register " +
        "participants from process definitions"
      ) if context['registerp_allowed'] != true
    end

    def register_participant(info)

      name, (klass, opts) = Ruote::ParticipantEntry.read(info)

      context.engine.register_participant(name, klass, opts)
    end
  end
end

