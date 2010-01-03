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
  # happening on a channel (a participant name).
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
  # == :to and :on
  #
  # The :to attribute has already been seen, it can be replaced by the :on one.
  #
  # Those two attributes are expected to hold regular expressions, so it's OK to
  # write things like :
  #
  #   listen :to => "^user\_.+"
  #
  # or
  #
  #   listen :to => /^user\_.+/
  #
  # To listen for workitems for all the participant whose name start with
  # "user_".
  #
  # == :wfid
  #
  # By default, a listen expression listens for any workitem/participant event
  # in the engine. Setting the :wfid attribute to 'true' or 'same' or 'current'
  # will make the listen expression only care for events belonging to the
  # same process instance (same wfid).
  #
  class ListenExpression < FlowExpression

    names :listen, :receive, :intercept

    def apply

      h.to = attribute(:to) || attribute(:on)

      upon = attribute(:upon) || 'apply'
      h.upon = (upon == 'reply') ? 'receive' : 'dispatch'

      h.lmerge = attribute(:merge).to_s
      h.lmerge = 'true' if h.lmerge == ''

      h.wfid = attribute(:wfid).to_s
      h.wfid = %w[ same current true ].include?(h.wfid)

      persist_or_raise

      @context.tracker.add_tracker(
        h.wfid ? h.fei['wfid'] : nil,
        h.upon,
        h.fei,
        { 'participant_name' => h.to },
        { 'action' => 'reply', 'fei' => h.fei, 'flavour' => 'listen' })
    end

    def reply (workitem)

      #
      # :where guard

      where = attribute(:where, workitem)
      return if where && ( ! Condition.true?(where))

      #
      # green for trigger

      wi = h.applied_workitem.dup

      if h.lmerge == 'true'
        wi['fields'].merge!(workitem['fields'])
      elsif h.lmerge == 'override'
        wi['fields'] = workitem['fields']
      #else don't touch
      end

      if tree_children.size > 0

        launch_sub(
          "#{h.fei['expid']}_0", tree[2][0], :forget => true, :workitem => wi)
      else

        reply_to_parent(wi)
      end
    end

    protected

    def reply_to_parent (workitem)

      @context.tracker.remove_tracker(h.fei)

      super(workitem)
    end
  end
end

