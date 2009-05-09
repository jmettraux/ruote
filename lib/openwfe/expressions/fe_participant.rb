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


require 'openwfe/utils'
require 'openwfe/rudefinitions'
require 'openwfe/expressions/filter'
require 'openwfe/expressions/timeout'


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

      return super_reply_to_parent(workitem) if conditional == false
        #
        # skip expression
        # <participant ref="x" if="y" /> (where y evals to false)

      @participant_name ||= self.respond_to?(:hint) ? hint : nil
      @participant_name ||= lookup_ref(workitem) || fetch_text_content(workitem)

      participant = get_participant_map.lookup_participant(@participant_name)

      raise "pexp : no participant named #{@participant_name.inspect}" \
        unless participant

      workitem.unset_result
      remove_timedout_flag(workitem)

      @applied_workitem = workitem.dup

      schedule_timeout(workitem)

      filter_in(workitem)

      store_itself

      workitem.params = lookup_attributes(workitem)

      # after the store_itself()

      get_participant_map.dispatch(
        participant, @participant_name, workitem)

      get_participant_map.onotify(
        @participant_name, :apply, workitem)
    end

    alias :super_reply_to_parent :reply_to_parent

    def reply_to_parent (workitem)

      get_participant_map.onotify(@participant_name, :reply, workitem)
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

      trigger_on_cancel # if any

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

        set_timedout_flag(@applied_workitem)

        reply_to_parent(@applied_workitem)

      rescue Exception => e

        lerror {
          "trigger() problem while timing out\n#{OpenWFE::exception_to_s(e)}"
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

      participant = get_participant_map.lookup_participant(@participant_name)

      cancelitem = CancelItem.new(@applied_workitem)

      get_participant_map.dispatch(participant, @participant_name, cancelitem)
    end
  end

end

