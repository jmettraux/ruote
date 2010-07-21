#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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


require 'ruote/exp/condition'


module Ruote::Exp

  #
  # The 'participant' expression is very special. It sits on the fence between
  # the engine and the external world.
  #
  # The participant expression is used to pass workitems to participants
  # from the engine. Those participants are bound at start time (usually) in
  # the engine via its register_participant method.
  #
  # Here's an example of two concurrent participant expressions in use :
  #
  #   concurrence do
  #     participant :ref => 'alice'
  #     participant :ref => 'bob'
  #   end
  #
  # Upon encountering the two expressions, the engine will lookup their name
  # in the participant map and hand the workitems to the participant instances
  # registered for those names.
  #
  #
  # == attributes passed as arguments
  #
  # All the attributes passed to a participant will be fed to the outgoing
  # workitem under a new 'params' field.
  #
  # Thus, with
  #
  #     participant :ref => 'alice', :task => 'maw the lawn', :timeout => '2d'
  #
  # Alice will receive a workitem with a field params set to
  #
  #     { :ref => 'alice', :task => 'maw the lawn', :timeout => '2d' }
  #
  # The fields named 'params' will be deleted before the workitems resumes
  # in the flow (with the engine replying to the parent expression of this
  # participant expression).
  #
  #
  # == simplified participant notation
  #
  # This process definition is equivalent to the one above. Less to write.
  #
  #   concurrence do
  #     participant 'alice'
  #     bob
  #   end
  #
  # Please note that 'bob' alone could stand for the participant 'bob' or
  # the subprocess named 'bob'. Subprocesses do take precedence over
  # participants (if there is a subprocess named 'bob' and a participant
  # named 'bob'.
  #
  #
  # == participant defined timeout
  #
  # Usually, timeouts are given for an expression in the process definition.
  #
  #   participant 'alice', :timeout => '2d'
  #
  # where alice as two days to complete her task (send back the workitem).
  #
  # But it's OK for participant classes registered in the engine to provide
  # their own timeout value. The participant instance simply has to reply to
  # the #timeout method and provide a meaningful timeout value.
  #
  # Note however, that the process definition timeout (if any) will take
  # precedence over the participant specified one.
  #
  #
  # == asynchronous
  #
  # The expression will make sure to dispatch to the participant in an
  # asynchronous way. This means that the dispatch will occur in a dedicated
  # thread.
  #
  # Since the dispatching to the participant could take a long time and block
  # the engine for too long, this 'do thread' policy is used by default.
  #
  # If the participant itself replies to the method #do_not_thread and replies
  # positively to it, a new thread (or a next_tick) won't get used. This is
  # practical for tiny participants that don't do IO and reply immediately
  # (after a few operations). By default, BlockParticipant instances do not
  # thread.
  #
  class ParticipantExpression < FlowExpression

    #include FilterMixin
      # TODO

    names :participant

    # Should return true when the dispatch was successful.
    #
    h_reader :dispatched

    h_reader :participant

    def apply

      #
      # determine participant

      h.participant_name = (attribute(:ref) || attribute_text).to_s

      raise ArgumentError.new(
        "no participant name specified"
      ) if h.participant_name == ''

      participant_info =
        h.participant ||
        @context.plist.lookup_info(h.participant_name, h.applied_workitem)

      unless participant_info.respond_to?(:consume)
        h.participant = participant_info
      end

      raise(ArgumentError.new(
        "no participant named #{h.participant_name.inspect}")
      ) if participant_info.nil?

      #
      # participant found, consider timeout

      schedule_timeout(participant_info)

      #
      # dispatch to participant

      h.applied_workitem['participant_name'] = h.participant_name
      h.applied_workitem['fields']['params'] = compile_atts

      persist_or_raise

      @context.storage.put_msg(
        'dispatch',
        'fei' => h.fei,
        'participant_name' => h.participant_name,
        'participant' => h.participant,
        'workitem' => h.applied_workitem,
        'for_engine_worker?' => (participant_info.class != Array))
    end

    def cancel (flavour)

      return reply_to_parent(h.applied_workitem) unless h.participant_name
        # no participant, reply immediately

      do_persist || return
        #
        # if do_persist returns false, it means we're operating on stale
        # data and cannot continue

      @context.storage.put_msg(
        'dispatch_cancel',
        'fei' => h.fei,
        'participant_name' => h.participant_name,
        'participant' => h.participant,
        'flavour' => flavour,
        'workitem' => h.applied_workitem)
    end

    def reply (workitem)

      pinfo =
        h.participant ||
        @context.plist.lookup_info(h.participant_name, workitem)

      pa = @context.plist.instantiate(pinfo, :if_respond_to? => :on_reply)

      pa.on_reply(Ruote::Workitem.new(workitem)) if pa

      super(workitem)
    end

    def reply_to_parent (workitem)

      workitem['fields'].delete('params')
      workitem['fields'].delete('dispatched_at')
      super(workitem)
    end

    protected

    # Once the dispatching work (done by the dispatch pool) is done, a
    # 'dispatched' msg is sent, we have to flag the participant expression
    # as 'dispatched' => true
    #
    # See http://groups.google.com/group/openwferu-users/browse_thread/thread/ff29f26d6b5fd135
    # for the motivation.
    #
    def do_dispatched (msg)

      h.dispatched = true
      do_persist
        # let's not care if it fails...
    end

    # Overriden with an empty behaviour. The work is now done a bit later
    # via the #schedule_timeout method.
    #
    def consider_timeout
    end

    # Determines and schedules timeout if any.
    #
    # Note that process definition timeout has priority over participant
    # specified timeout.
    #
    def schedule_timeout (p_info)

      timeout = attribute(:timeout)

      unless timeout
        pa = @context.plist.instantiate(p_info, :if_respond_to? => :timeout)
        timeout = pa.timeout if pa
      end

      do_schedule_timeout(timeout)
    end
  end
end

