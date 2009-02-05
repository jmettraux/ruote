#
#--
# Copyright (c) 2006-2009, John Mettraux, OpenWFE.org
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

require 'openwfe/logging'
require 'openwfe/contextual'
require 'openwfe/rudefinitions'


module OpenWFE

  #
  # The 'participant' concept is displayed as a module, so that
  # other pieces of code may easily 'mix it in'.
  #
  # Participant extensions should at least provide a consume(workitem)
  # method.
  # As an option, it can provide a cancel(cancelitem) method.
  #
  # The engine will transmit instances of OpenWFE:WorkItem via the
  # consume method.
  #
  # If there is a cancel method available and an OpenWFE::CancelItem instance
  # is emitted (cancelling a process or part of it), it will be fed to
  # the participant only via the cancel method.
  #
  # If there is no cancel method, the participant will not get notified
  # of the cancellation.
  #
  module Participant

    #
    # A Participant will be receiving OpenWFE::WorkItem's via this method.
    #
    def consume (workitem)

      raise NotImplementedError.new(
        "implementation for method consume() "+
        "is missing in class '#{self.class}'")
    end

    #--
    # (optional)
    #
    #def cancel (cancelitem)
    #end
    #++

    #
    # By default, returns false. When returning true the dispatch to the
    # participant will not be done in his own thread.
    #
    # Since ActiveRecord 2.2, ActiveParticipant returns true (well, this
    # method was introduced for ActiveParticipant and AR 2.2)
    #
    def do_not_thread
      false
    end
  end

  #
  # Local participants provide handy methods like reply_to_engine() to
  # further implementations of the Participant concept.
  #
  module LocalParticipant
    include Participant, Contextual, Logging, OwfeServiceLocator

    #
    # Returns the FlowExpression instance that triggered this
    # participant.
    # A ParticipantExpression instance will most likely be returned.
    #
    def get_flow_expression (workitem)

      return nil if not @application_context

      get_expression_pool.fetch_expression(workitem.flow_expression_id)
    end

    #
    # A convenience method for calling block passed to participants
    # for templates (mail participants) or execution (BlockParticipant).
    #
    # Allows for such blocks :
    #
    #   { |workitem| ... }
    #   { |participant_expression, workitem| ... }
    #   { |participant_expression, participant, workitem| ... }
    #
    # For 0 or more than 3 arguments, the block will be called without
    # arguments.
    #
    def call_block (block, workitem)

      if block.arity == 1
        block.call(workitem)
      elsif block.arity == 2
        block.call(get_flow_expression(workitem), workitem)
      elsif block.arity == 3
        block.call(get_flow_expression(workitem), self, workitem)
      else
        block.call
      end
    end

    #
    # Participants use this method to reply to their engine when
    # their job is done.
    #
    def reply_to_engine (workitem)

      get_engine.reply(workitem)
    end
  end

end

