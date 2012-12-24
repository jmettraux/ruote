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
  # The 'await' expression is the successor of the 'listen' expression
  # (Ruote::Exp::ListenExpression). It's been introduced in ruote 2.3.0.
  #
  # Hopefully it has a simpler syntax than 'listen'. The major difference
  # between listen and await is that await, by default, listens only
  # to events in the same process instance.
  #
  # This expression blocks until an event occurs somewhere else in the same
  # process instance.
  #
  #   concurrence do
  #     sequence do
  #       participant 'alice'
  #       await :left_tag => 'a'
  #       participant 'bob'
  #     end
  #     sequence :tag => 'a' do
  #       participant 'charly'
  #       participant 'doug'
  #     end
  #     sequence do
  #       participant 'eric'
  #     end
  #   end
  #
  # In this example, the flow between alice and bob, will block until 'doug'
  # has replied (Yes, this example could have been written using
  # :left_participant => 'doug').
  #
  # == modes
  #
  # 'await', like 'listen' works in two mode, "once" and "multiple times".
  #
  # In the 'once' mode, the await expression blocks the flow until the workitem
  # (somewhere else in the process instance) leaves the alice participant:
  #
  #   sequence do
  #     await :left_participant => 'alice'
  #     participant 'eric'
  #   end
  #
  # In the 'multiple times' mode, the await expression triggers its children
  # expressions each time a matching event occurs. It never replies to its
  # parent expression. Here, the participant 'post_alice' will receive a
  # workitem each time, somewhere else in the process
  #
  #   await :left_participant => 'alice' do
  #     participant 'post_alice'
  #   end
  #
  # Note, that, unlike "listen" in previous versions of ruote, it's OK
  # to consider the children of "await" as part of an implicit sequence:
  #
  #   await :left_participant => 'alice' do
  #     participant 'bob'
  #     participant 'charly'
  #   end
  #
  # Bob and charly will be applied in sequence.
  #
  # == tag, participant or error events
  #
  # Await listens to 3 types of events: tag, participant and error events.
  #
  # Here is a assortment of examples:
  #
  #   await :in_participant => 'alice'
  #   await :reached_participant => 'alice'
  #   await :out_participant => 'alice'
  #   await :left_participant => 'alice'
  #
  #   await :participant => 'alice'
  #   await :participants => 'alice' # looks better with an array
  #
  #   # implicit OR with arrays:
  #   #
  #   await :in_participant => /^al/
  #   await :in_participant => %w[ alice alfred ]
  #   await :in_participant => [ /^al/, /fred$/ ]
  #
  #   await :in_tag => 'phase2'
  #   await :reached_tag => 'phase2'
  #   await :out_tag => 'phase2'
  #   await :left_tag => 'phase2'
  #
  #   await :tags => 'phase2'
  #
  #   await :error
  #   await :error => 'ArgumentError'
  #   await :error => 'RuntimeError, ArgumentError'
  #   await :error => %w[ RuntimeError ArgumentError ]
  #
  # Basically, the attribute is composed of a left part and a right part.
  # The right part is one of "in", "reached" or "out", "left". "in" and
  # "reached" are equivalent, as are "out" and "left".
  #
  # The right part is "tag" or "participant".
  #
  # "error" can be used alone.
  #
  # When "tags" and "participant(s)" are used alone, they are synonymous with
  # "reached_tag" and "reached_participant" respectively.
  #
  # === absolute tags
  #
  # It's OK to specify absolute tags, like in:
  #
  #   pdef = Ruote.define do
  #     concurrence do
  #       sequence do
  #         await :tag => 'a/b'
  #         echo 'a/b'
  #       end
  #       sequence :tag => 'a' do
  #         noop
  #         sequence :tag => 'b' do
  #           echo 'b'
  #         end
  #       end
  #     end
  #   end
  #
  # == :where condition
  #
  # The "await" expression accepts an optional attribute which adds another
  # guard which is checked to determine if the trigger should occur or not.
  #
  #   pdef = Ruote.process_definition do
  #     concurrence :wait_for => 1 do
  #       await :left_participant => 'a', :where => "${task} == 'sing'" do
  #         echo 'sing-a'
  #       end
  #       await :left_participant => 'a' do
  #         echo 'any-a'
  #       end
  #       concurrence do
  #         participant 'a', :task => 'talk'
  #         participant 'a', :task => 'sing'
  #       end
  #     end
  #   end
  #
  # In this example, the message 'sing-a' will be echoed only once (twice for
  # 'any-a').
  #
  #
  # == :global => false by default
  #
  # Unlike the 'listen' expression, 'await', by default, only triggers for
  # events in the same process instance. To react on events whatever the
  # process instance, :global => true (or "true") can be used.
  #
  #   await :left_tag => 'phase1', :global => true do
  #     participant 'supervisor', :msg => 'phase1 over'
  #   end
  #
  #
  # == :merge => nil/ignore
  #
  # In the listen expression, the default is for the event's workitem to
  # get merged into the waiting workitem. With 'await', the default is
  # the event's workitem completely overriding the awaiting workitem.
  #
  # Using the :merge attribute, other behaviours are possible.
  #
  #   await :left_tag => 'phase3', :merge => 'ignore'
  #   await :left_tag => 'phase3', :merge => 'drop'
  #     # the event's workitem is ignored, the awaiting workitem is used
  #
  #   await :left_tag => 'phase3', :merge => 'override'
  #     # the event's workitem is used, this is the default
  #
  #   await :left_tag => 'phase3', :merge => 'incoming'
  #     # a hash merge happens, the incoming (event) workitem wins
  #     # workitem = awaiting.merge(incoming)
  #
  #   await :left_tag => 'phase3', :merge => 'awaiting'
  #     # a hash merge happens, the awaiting workitem wins
  #     # workitem = incoming.merge(awaiting)
  #
  # Note: the :where guard is always about the event's workitem (not the
  # workitem as it reached the 'await' expression).
  #
  #
  # == note: the "await" attribute
  #
  # (since ruote 3.2.1)
  #
  # "listen" and "await" are both ruote expressions. There is also an
  # attribute common to all the expressions: :await.
  #
  #   concurrence do
  #     sequence do
  #       alice
  #       sequence :tag => 'stage2' do
  #         bob
  #       end
  #     end
  #     sequence do
  #       charly
  #       diana :await => 'left_tag:stage2'
  #       eliza
  #     end
  #     frank
  #   end
  #
  # The expressions with an await attribute suspends its application until
  # the awaited event happens.
  #
  # This await attribute, defaults to "left_tag:", so
  #
  #   diana :await => 'stage2'
  #     # is equivalent to
  #   diana :await => 'left_tag:stage2'
  #
  class AwaitExpression < FlowExpression

    names :await

    def apply

      #
      # gathering info

      action, condition = self.class.extract_await_ac(attributes)

      raise ArgumentError.new(
        "couldn't determine which event to listen to from: " +
        attributes.inspect
      ) unless action

      global = (attribute(:global).to_s == 'true')
      global = false if action == 'error_intercepted'

      h.amerge = attribute(:merge).to_s

      persist_or_raise

      #
      # adding a new tracker

      @context.tracker.add_tracker(
        global ? nil : h.fei['wfid'],
        action,
        Ruote.to_storage_id(h.fei),
        condition,
        { 'action' => 'reply',
          'fei' => h.fei,
          'workitem' => 'replace',
          'flavour' => 'await' })
    end

    def reply(workitem)

      #
      # :where guard

      where = attribute(:where, workitem)
      return if where && Condition.false?(where)

      #
      # merge

      wi = h.applied_workitem.dup

      wi['fields'] =
        case h.amerge
          when 'ignore', 'drop' then wi['fields']
          when 'incoming' then wi['fields'].merge(workitem['fields'])
          when 'awaiting' then workitem['fields'].merge(wi['fields'])
          else workitem['fields'] # 'override'
        end

      #
      # actual trigger

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

    INS = %w[ in entered reached ]
    OUTS = %w[ out left ]

    SPLIT_R =
      /^(?:(#{(INS + OUTS).join('|')})_)?(tag|participant|error)s?$/

    # attribute wait regex
    AAWAIT_R =
      /^(?:(#{(INS + OUTS).join('|')})_)?(tag|participant)s?\s*:\s*(.+)$/

    # matches Ruby class names, like "Ruote::ForcedError" or "::ArgumentError"
    KLASS_R =
      /^(::)?([A-Z][a-z]+)+(::([A-Z][a-z]+)+)*$/

    # Made into a class method, so that the :await common attribute can
    # use it when parsing :await...
    #
    def self.extract_await_ac(atts)

      direction, type, value =
        atts.collect { |k, v|
          if k == :await && m = AAWAIT_R.match(v)
            [ m[1] || 'in', m[2], m[3] ]
          elsif k == :await && v.index(':').nil?
            [ 'left', 'tag', v ]
          elsif m = SPLIT_R.match(k)
            [ m[1] || 'in', m[2], v ]
          else
            nil
          end
        }.compact.first

      return nil if direction == nil

      action =
        if type == 'tag'
          INS.include?(direction) ? 'entered_tag' : 'left_tag'
        elsif type == 'participant'
          INS.include?(direction) ? 'dispatch' : 'receive'
        else # error
          'error_intercepted'
        end

      value = Ruote.comma_split(value)

      condition =
        if type == 'participant'

          { 'participant_name' => value }

        elsif type == 'error'

          # array or comma string or string ?

          h = { 'class' => [], 'message' => [] }

          value.each { |e| (KLASS_R.match(e) ? h['class'] : h['message']) << e }

          h.delete_if { |k, v| v == nil or v == [] }

        else # 'tag'

          { (value.first.to_s.match(/\//) ? 'full_tag' : 'tag') => value }
        end

      [ action, condition ]
    end
  end
end

