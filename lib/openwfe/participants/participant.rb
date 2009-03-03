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

    include Participant
    include Contextual
    include Logging
    include OwfeServiceLocator

    #
    # Returns the FlowExpression instance that triggered this
    # participant.
    # A ParticipantExpression instance will most likely be returned.
    #
    def get_flow_expression (workitem)

      return nil unless @application_context

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

