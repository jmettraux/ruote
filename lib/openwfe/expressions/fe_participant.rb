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

require 'openwfe/utils'
require 'openwfe/rudefinitions'
require 'openwfe/expressions/filter'
require 'openwfe/expressions/timeout'


#
# The participant expression, in its own file
#

module OpenWFE

  #
  # Participants sit at the edge between the engine and the external
  # world. The participant expression transmit the workitem applied
  # to it to the Participant instance it looks up in the participant map
  # tied to the engine.
  #
  #  direct reference to participant alpha :
  #
  #   <participant ref="alpha" />
  #
  #  the name of the participant is the value found in
  #  the field 'target' :
  #
  #   <participant field-ref="target" />
  #   <participant ref="${f:target}" />
  #
  #  the name of the participant is the value found in
  #  the variable 'target' :
  #
  #   <participant variable-ref="target" />
  #   <participant ref="${target}" />
  #
  #  direct reference to participant 'alpha'
  #  if a subprocess named 'alpha' has been defined, the
  #  subprocess will be called instead :
  #
  #   <alpha />
  #
  # The Participant expressions includes the FilterMixin and thus
  # understands and applies the "filter" attribute.
  #
  # Since OpenWFEru 0.9.9, the attributes of the participant expression are
  # set inside a hash field named 'params' just available to the participant.
  # Thus in
  #
  #   <participant ref="toto" task="play golf" location="Minami Center" />
  #
  # participant 'toto' will receive a workitem with a field named 'params'
  # containing the hash
  # { "ref"=>"toto", "task"=>"play golf", "location"=>"Minami Center" }.
  #
  # When the workitem gets back from the participant, the field 'params' is
  # deleted.
  #
  # The participant expressions include the TimeoutMixin, it means that
  # a timeout can be stated :
  #
  #   <participant ref="toto" timeout="2w1d" />
  #
  # If after 2 weeks and 1 day (15 days), participant "toto" hasn't replied,
  # the workitem will get cancelled and the flow will resume (behind the
  # scene, participant "toto", will receive a CancelItem instance bearing
  # the same FlowExpressionId as the initial workitem and the participant
  # implementation is responsible for the cancel application).
  #
  # The participant expression accepts an optional 'if' (or 'unless')
  # attribute. It's used for conditional execution of the participant :
  #
  #   participant :ref => "toto", :if => "${weather} == raining"
  #     # the participant toto will receive a workitem only if
  #     # it's raining
  #
  #   boss :unless => "#{f:matter} == 'very trivial'"
  #     # the boss will not participate in the proces if the matter
  #     # is 'very trivial'
  #
  class ParticipantExpression < FlowExpression
    include FilterMixin
    include TimeoutMixin
    include ConditionMixin

    names :participant

    attr_accessor :participant_name
    attr_accessor :applied_workitem


    def apply (workitem)

      conditional = eval_condition(:if, workitem, :unless)

      return super_reply_to_parent(workitem) \
        if conditional == false
          #
          # skip expression
          # <participant ref="x" if="y" /> (where y evals to false)

      @participant_name = lookup_ref workitem

      @participant_name = fetch_text_content workitem \
        unless @participant_name

      participant =
        get_participant_map.lookup_participant @participant_name

      raise "No participant named '#{@participant_name}'" \
        unless participant

      remove_timedout_flag workitem

      @applied_workitem = workitem.dup

      schedule_timeout(workitem)

      filter_in(workitem)

      store_itself

      workitem.params = lookup_attributes(workitem)

      #
      # threading AFTER the store_itself()
      #
      Thread.new do
        begin

          # these two pmap calls were combined, but with the :reply
          # notification in reply_to_parent() it feels more
          # elegant like that

          get_participant_map.dispatch(
            participant, @participant_name, workitem)

          get_participant_map.onotify(
            @participant_name, :apply, workitem)

        rescue Exception => e

          get_expression_pool.notify_error(
            e, fei, :apply, workitem)
        end
      end
    end

    alias :super_reply_to_parent :reply_to_parent

    def reply_to_parent (workitem)

      get_participant_map.onotify @participant_name, :reply, workitem
        #
        # for 'listen' expressions waiting for replies

      unschedule_timeout(workitem)

      workitem.attributes.delete('params')

      filter_out(workitem)

      super(workitem)
    end

    #
    # The cancel() method of a ParticipantExpression is particular : it
    # will emit a CancelItem instance towards the participant itself
    # to notify it of the cancellation.
    #
    def cancel

      unschedule_timeout(nil)

      cancel_participant

      @applied_workitem
    end

    #
    # Upon timeout, the ParticipantExpression will cancel itself and
    # the flow will resume.
    #
    def trigger (scheduler)

      linfo { "trigger() timeout requested for #{@fei.to_debug_s}" }

      begin

        #@scheduler_job_id = nil
          #
          # so that cancel won't unschedule without need

        cancel_participant

        set_timedout_flag @applied_workitem

        reply_to_parent @applied_workitem

      rescue

        lerror {
          "trigger() problem while timing out\n#{OpenWFE::exception_to_s($!)}"
        }
      end
    end

    protected

      #
      # Have to cancel the workitem on the participant side
      #
      def cancel_participant

        return unless @applied_workitem
          #
          # if there is an applied workitem, it means there
          # is a participant to cancel...

        participant =
          get_participant_map.lookup_participant(@participant_name)

        cancelitem = CancelItem.new(@applied_workitem)

        get_participant_map.dispatch(
          participant, @participant_name, cancelitem)
      end
  end

end

