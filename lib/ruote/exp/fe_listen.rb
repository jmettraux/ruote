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


require 'ruote/exp/condition'


module Ruote::Exp

  #
  # Listens for activity (incoming or outgoing workitems) on a (set of)
  # participant(s).
  #
  # This expression is an advanced one. It allows for cross process instance
  # communication or at least cross branch communication within the same
  # process instance.
  #
  # DO NOT confuse the listen expression with the 'listener' concept. They are
  # not directly related. The listen expression listens to workitem activity
  # inside of the engine, while a listener listens for workitems or launchitems
  # from sources external to the ruote workflow engine.
  #
  # It can be used in two ways : 'blocking' or 'triggering'. In both cases
  # the listen expression 'reacts' upon activity (incoming or outgoing workitem)
  # happening on a channel (a participant name or a tag name).
  #
  # == blocking
  #
  # A blocking example :
  #
  #   sequence do
  #     participant 'alice'
  #     listen :to => 'bob'
  #     participant 'charly'
  #   end
  #
  # Once the listen expression got applied, this process will block until a
  # workitem (in any other process instance in the same engine) is dispatched
  # to participant 'bob'. It then proceeds to charly.
  #
  # == triggering
  #
  # This way of using 'listen' is useful for launching processes that "stalk"
  # other processes :
  #
  #   Ruote.process_definition :name => 'stalker' do
  #     listen :to => 'bob' do
  #       participant :ref => 'charly'
  #     end
  #   end
  #
  # This small process will never exits and will send a workitem to charly
  # each time the ruote engine sends a workitem to bob.
  #
  # The workitems passed to charly will be copies of the workitem initially
  # applied to the 'listen' expression, but with a copy of the fields of the
  # workitem passed to bob, merged in.
  #
  # Note : for now, the triggered segments of processes are 'forgotten'. The
  # 'listen' expression doesn't keep track of them. This also means that in
  # case of cancel, the triggered segments will not get cancelled.
  #
  # == :merge
  #
  # By default, :merge is set to true, the listened for workitems see their
  # values merged into a copy of the workitem held in the listen expression
  # and this copy is delivered to the expressions that are client to the
  # 'listen'.
  #
  # :merge can be set to 'override' where the event's workitem fields are
  # used or some value which isn't true or 'true', in which case the
  # workitem fields of the 'listen' expression is used as is (as it was
  # when the flow reached the 'listen' expression).
  #
  # == :upon
  #
  # There are two kinds of main events in ruote, apply and reply. Thus,
  # a listen expression may listen to 'apply' and to 'reply' and this is
  # defined by the :upon attribute.
  #
  # By default, listens upon 'apply' (engine handing workitem to participant).
  #
  # Can be set to 'reply', to react on workitems being handed back to the
  # engine by the participant.
  #
  # Setting :upon to 'entering' or 'leaving' tells the listen to focus on
  # tag events.
  #
  #   sequence do
  #     sequence :tag => 'phase_one' do
  #       alpha
  #     end
  #     sequence :tag => 'phase_two' do
  #       bravo
  #     end
  #   end
  #
  # In this dummy process definition, there are four tag events :
  #
  # * 'entering' 'phase_one'
  # * 'leaving' 'phase_one'
  # * 'entering' 'phase_two'
  # * 'leaving' 'phase_two'
  #
  # When listening to tags, absolute paths can be given.
  #
  #   concurrence do
  #     sequence :tag => 'a' do
  #       alpha
  #       sequence :tag => 'b' do
  #         bravo
  #       end
  #     end
  #     sequence do
  #       listen :to => 'a/b', :upon => 'entering'
  #       charly
  #     end
  #    end
  #   end
  #
  # Charly will be next when the flow is about to reach bravo.
  #
  #
  # == :to and :on
  #
  # The :to attribute has already been seen, it can be replaced by the :on one.
  #
  #   listen :to => 'alpha'
  #
  # is equivalent to
  #
  #   listen :on => 'alpha'
  #
  #
  # == :to (:on) and regular expressions
  #
  # It's OK to write things like :
  #
  #   listen :to => "/^user\_.+/"
  #
  # or
  #
  #   listen :to => /^user\_.+/
  #
  # To listen for workitems for all the participant whose name start with
  # "user_".
  #
  #
  # == :wfid
  #
  # By default, a listen expression listens for any workitem/participant event
  # in the engine. Setting the :wfid attribute to 'true' or 'same' or 'current'
  # will make the listen expression only care for events belonging to the
  # same process instance (same wfid).
  #
  #
  # == :where
  #
  # The :wfid can be considered a 'guard'. Another tool for guarding listen
  # is to use the :where attribute.
  #
  #   listen :to => 'alpha', :where => '${customer.state} == CA'
  #
  # The listen will trigger only if the workitem has a customer field with
  # a subfield state containing the value "CA".
  #
  # The documentation about the dollar notation and the one about common
  # attributes :if and :unless applies for the :where attribute.
  #
  #
  # == listen :to => :errors
  #
  # The listen expression can be made to listen to errors.
  #
  #   listen :to => errors do
  #     participant 'supervisor_sms', :task => 'verify system'
  #   end
  #
  # Whenever an error happens in the process with this listen stance,
  # the listen will trigger.
  #
  # "listen :to => :errors" only works with errors in the same process instance
  # (same wfid).
  #
  # "listen :to => :errors" doesn't trigger when the error is caught (via
  # :on_error).
  #
  # === listen :to => :errors, :class => 'ArgumentError'
  #
  # One can restrict the listen to certain classes of errors.
  # Passing a list of error classes separated by a comma is OK.
  #
  # === listen :to => :errors, :message => /x/
  #
  # One can restrict the error listening to errors matching a certain regex
  # or equal to a certain string. The attribute is :message or :msg. The
  # value is a String (strict equality) or a Regex (matching).
  #
  class ListenExpression < FlowExpression

    names :listen, :receive, :intercept

    UPONS = {
      'apply' => 'dispatch', 'reply' => 'receive',
      'entering' => 'entered_tag', 'leaving' => 'left_tag'
    }

    def apply

      # gathering info

      h.to = attribute(:to) || attribute(:on)

      h.upon = UPONS[attribute(:upon) || 'apply']
      h.upon = 'error_intercepted' if h.to == 'errors'

      h.lmerge = attribute(:merge).to_s
      h.lmerge = 'true' if h.lmerge == ''

      h.lwfid = attribute(:wfid).to_s
      h.lwfid = %w[ same current true ].include?(h.lwfid)

      h.lwfid = true if h.to == 'errors'
        # can only listen to errors in the same process instance

      persist_or_raise

      # adding a new tracker

      @context.tracker.add_tracker(
        h.lwfid ? h.fei['wfid'] : nil,
        h.upon,
        Ruote.to_storage_id(h.fei),
        determine_condition,
        { 'action' => 'reply',
          'fei' => h.fei,
          'workitem' => 'replace',
          'flavour' => 'listen' })
    end

    def reply(workitem)

      #
      # :where guard

      where = attribute(:where, workitem)
      return if where && Condition.false?(where)

      #
      # green for trigger

      wi = h.applied_workitem.dup

      if h.lmerge == 'true'
        wi['fields'].merge!(workitem['fields'])
      elsif h.lmerge == 'override'
        wi['fields'] = workitem['fields']
      #else don't touch
      end

      if tree_children.any?

        i, t = if tree_children.size == 1
          [ "#{h.fei['expid']}_0", tree_children[0] ]
        else
          [ h.fei['expid'], [ 'sequence', {}, tree_children ] ]
        end

        launch_sub(i, t, :forget => true, :workitem => wi)

      else

        reply_to_parent(wi)
      end
    end

    protected

    # Overriding the parent's #reply_to_parent to make sure the tracker is
    # removed before (expression terminating, no need for it to track anything
    # anymore).
    #
    def reply_to_parent(workitem)

      @context.tracker.remove_tracker(h.fei)

      super(workitem)
    end

    def determine_condition

      if h.upon == 'dispatch' || h.upon == 'receive'

        { 'participant_name' => h.to }

      elsif h.upon == 'error_intercepted'

        {
          'class' => Ruote.comma_split(attribute(:class) || ''),
          'message' => attribute(:message) || attribute(:msg)
        }.delete_if { |k, v|
          v == nil or v == []
        }

      else

        { (h.to.match(/\//) ? 'full_tag' : 'tag') => h.to }
      end
    end
  end
end

