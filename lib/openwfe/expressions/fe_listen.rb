#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/expressions/merge'
require 'openwfe/expressions/timeout'
require 'openwfe/expressions/condition'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # An expression for listening to participant activity in the engine
  # (across process instances).
  #
  #   <listen to="alice">
  #     <subprocess ref="notify_bob" />
  #   </listen>
  #
  # Whenever a workitem is dispatched (applied) to the participant
  # named "alice", the subprocess named "notify_bob" is triggered (once).
  #
  #   listen :to => "^channel_.*", :upon => "reply" do
  #     sequence do
  #       participant :ref => "delta"
  #       participant :ref => "echo"
  #     end
  #   end
  #
  # After the listen has been applied, the first workitem coming back from
  # a participant whose named starts with "channel_" will trigger a sequence
  # with the participants 'delta' and 'echo'.
  #
  #   listen :to => "alpha", :where => "${f:color} == red" do
  #     participant :ref => "echo"
  #   end
  #
  # Will send a copy of the first workitem meant for participant "alpha" to
  # participant "echo" if this workitem's color field is set to 'red'.
  #
  #   listen :to => "alpha", :once => "false" do
  #     send_email_to_stakeholders
  #   end
  #
  # This is some kind of a server : each time a workitem is dispatched to
  # participant "alpha", the subprocess (or participant) named
  # 'send_email_to_stakeholders') will receive a copy of that workitem.
  # Use with care.
  #
  #   listen :to => "alpha", :once => "false", :timeout => "1M2w" do
  #     send_email_to_stakeholders
  #   end
  #
  # The 'listen' expression understands the 'timeout' attribute. It can thus
  # be instructed to stop listening after a certain amount of time (here,
  # after one month and two weeks).
  #
  # The listen expression can be used without a
  # child expression. It blocks until a valid messages comes in the
  # channel, at which point it resumes the process, with workitem that came
  # as the message (not with the workitem at apply time).
  # (no merge implemented for now).
  #
  #   sequence do
  #     listen :to => "channel_z", :upon => :reply
  #     participant :the_rest_of_the_process
  #   end
  #
  # In this example, the process will block until a workitem comes for
  # a participant named 'channel_z'.
  #
  # The engine accept (in its reply()
  # method) workitems that don't belong to a process intance (ie workitems
  # that have a nil flow_expression_id). So it's entirely feasible to
  # send 'notifications only' workitems to the OpenWFEru engine.
  # (see http://github.com/jmettraux/ruote/tree/master/test/ft_54b_listen.rb)
  #
  # This expression has been aliased 'intercept'
  # and 'receive'. It also accepts the 'on' parameter as an alias parameter
  # to the 'to' parameter. Think "listen to" and "receive on".
  #
  # A 'merge' attribute can be set to true (the
  # default value being false), the incoming workitem will then be merged
  # with a copy of the workitem that 'applied' (activated) the listen
  # expression.
  #
  # Since Ruote 0.9.20, a 'wfid' attribute is available. When set to :current
  # or 'current', it indicates that the listen is only concerned with the
  # current process instance. It's handy for defining intra process listens.
  #
  class ListenExpression < FlowExpression
    include TimeoutMixin
    include ConditionMixin
    include MergeMixin

    names :listen, :intercept, :receive

    #
    # the channel on which this expression 'listens'
    #
    attr_accessor :participant_regex

    #
    # is set to true if the expression listen to 1! workitem and
    # then replies to its parent.
    # When set to true, it listens until the process it belongs to
    # terminates.
    # The default value is true.
    #
    attr_accessor :once

    #
    # can take :apply or :reply as a value, if not set (nil), will listen
    # on both 'directions'.
    #
    attr_accessor :upon

    #
    # 'listen' accepts a :merge attribute, when set to true, this
    # field will contain a copy of the workitem that activated the
    # listen activity. This copy will be merged with incoming (listened
    # for) workitems when triggering the listen child.
    #
    attr_accessor :applied_workitem

    #
    # how many messages were received (can more than 0 or 1 if 'once'
    # is set to false).
    #
    attr_accessor :call_count


    def apply (workitem)

      #return reply_to_parent(workitem) if has_no_expression_child
        # 'listen' blocks if there is no children

      #
      # participant regex

      @participant_regex =
        lookup_string_attribute(:to, workitem) ||
        lookup_string_attribute(:on, workitem)

      raise "attribute 'to' is missing for expression 'listen'" \
        unless @participant_regex

      #
      # wfid

      @wfid_regex =
        lookup_string_attribute(:wfid, workitem).to_s.strip == 'current'

      #
      # once

      @once =
        has_no_expression_child ||
        lookup_boolean_attribute(:once, workitem, true)

      #
      # merge

      merge = lookup_boolean_attribute(:merge, workitem, false)

      @applied_workitem = workitem.dup if merge

      #
      # upon

      @upon = lookup_sym_attribute(:upon, workitem, :default => :apply)
      @upon = (@upon == :reply) ? :reply : :apply

      @call_count = 0

      determine_timeout(nil) # workitem set to nil, no stamp needed.
      reschedule(get_scheduler)

      store_itself
    end

    def cancel

      stop_observing
      super
    end

    def reply_to_parent (workitem)

      ldebug { "reply_to_parent() 'listen' done." }

      stop_observing
      super
    end

    #
    # Only called in case of timeout.
    #
    def trigger (params)

      reply_to_parent(workitem)
    end

    #
    # This is the method called when a 'listenable' workitem comes in
    #
    def call (channel, *args)

      upon = args[0]

      ldebug { "call() channel : '#{channel}' upon '#{upon}'" }

      return if upon != @upon

      workitem = args[1].dup

      if @wfid_regex

        wfid = workitem.fei.wfid(true)

        if @wfid_regex == true
          return if wfid != self.fei.wfid(true)
        else
          return unless wfid.match(@wfid_regex)
        end
      end

      conditional = eval_condition(:where, workitem)
        #
        # note that the values if the incoming workitem (not the
        # workitem at apply time) are used for the evaluation
        # of the condition (if necessary).

      return if conditional == false

      return if @once and @call_count > 0

      #
      # workitem does match...

      ldebug do
        "call() "+
        "through for fei #{workitem.fei} / "+
        "'#{workitem.participant_name}'"
      end

      @call_count += 1

      #ldebug { "call() @call_count is #{@call_count}" }

      #
      # eventual merge

      workitem = merge_workitems(@applied_workitem.dup, workitem) \
        if @applied_workitem

      #
      # reply or launch nested child expression

      return reply_to_parent(workitem) if has_no_expression_child
        # was just a "blocking listen"

      get_expression_pool.tlaunch_child(
        self,
        raw_children.first,
        @call_count - 1,
        workitem,
        :orphan => (not @once),
        :register_child => true) # (in case of cancel)

      #store_itself
        # now done in tlaunch_child()
    end

    #
    # Registers for timeout and start observing the participant
    # activity.
    #
    def reschedule (scheduler)

      to_reschedule(scheduler)
      start_observing
    end

    protected

      #
      # Start observing a [participant name] channel.
      #
      def start_observing

        get_participant_map.add_observer(@participant_regex, self)
      end

      #
      # Expression's job is over, deregister.
      #
      def stop_observing

        get_participant_map.remove_observer(self)
      end
  end

end

