#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

require 'openwfe/expressions/merge'
require 'openwfe/expressions/timeout'
require 'openwfe/expressions/condition'
require 'openwfe/expressions/flowexpression'


module OpenWFE

    #
    # The "listen" expression can be viewed in two ways :
    #
    # 1)
    # It's a hook into the participant map to intercept apply or reply
    # operations on participants.
    #
    # 2)
    # It allows OpenWFE[ru] to be a bit closer to the 'ideal' process-calculus
    # world (http://en.wikipedia.org/wiki/Process_calculi)
    #
    # Anyway...
    #
    #     <listen to="alice">
    #         <subprocess ref="notify_bob" />
    #     </listen>
    #
    # Whenever a workitem is dispatched (applied) to the participant
    # named "alice", the subprocess named "notify_bob" is triggered (once).
    #
    #     listen :to => "^channel_.*", :upon => "reply" do
    #         sequence do
    #             participant :ref => "delta"
    #             participant :ref => "echo"
    #         end
    #     end
    #
    # After the listen has been applied, the first workitem coming back from
    # a participant whose named starts with "channel_" will trigger a sequence
    # with the participants 'delta' and 'echo'.
    #
    #     listen :to => "alpha", :where => "${f:color} == red" do
    #         participant :ref => "echo"
    #     end
    #
    # Will send a copy of the first workitem meant for participant "alpha" to
    # participant "echo" if this workitem's color field is set to 'red'.
    #
    #     listen :to => "alpha", :once => "false" do
    #         send_email_to_stakeholders
    #     end
    #
    # This is some kind of a server : each time a workitem is dispatched to
    # participant "alpha", the subprocess (or participant) named
    # 'send_email_to_stakeholders') will receive a copy of that workitem.
    # Use with care.
    #
    #     listen :to => "alpha", :once => "false", :timeout => "1M2w" do
    #         send_email_to_stakeholders
    #     end
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
    #     sequence do
    #         listen :to => "channel_z", :upon => :reply
    #         participant :the_rest_of_the_process
    #     end
    #
    # In this example, the process will block until a workitem comes for
    # a participant named 'channel_z'.
    #
    # The engine accept (in its reply()
    # method) workitems that don't belong to a process intance (ie workitems
    # that have a nil flow_expression_id). So it's entirely feasible to
    # send 'notifications only' workitems to the OpenWFEru engine.
    # (see http://openwferu.rubyforge.org/svn/trunk/openwfe-ruby/test/ft_54b_listen.rb)
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
    class ListenExpression < FlowExpression
        include TimeoutMixin
        include ConditionMixin
        include MergeMixin

        names :listen, :intercept, :receive

        uses_template

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

            #if @children.size < 1
            #    reply_to_parent workitem
            #    return
            #end
                #
                # 'listen' now blocks if there is no children

            @participant_regex = lookup_string_attribute(:to, workitem)

            @participant_regex = lookup_string_attribute(:on, workitem) \
                unless @participant_regex

            raise "attribute 'to' is missing for expression 'listen'" \
                unless @participant_regex

            ldebug { "apply() listening to '#{@participant_regex}'" }

            #
            # once

            @once = lookup_boolean_attribute :once, workitem, true

            @once = true if raw_children.size < 1
                # a 'blocking listen' can only get triggered once.

            ldebug { "apply() @once is #{@once}" }

            #
            # merge

            merge = lookup_boolean_attribute :merge, workitem, false

            ldebug { "apply() merge is #{@merge}" }

            @applied_workitem = workitem.dup if merge

            #
            # upon

            @upon = lookup_sym_attribute(
                :upon, workitem, :default => :apply)

            @upon = (@upon == :reply) ? :reply : :apply

            ldebug { "apply() @upon is #{@upon}" }

            @call_count = 0

            determine_timeout
            reschedule get_scheduler

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

            reply_to_parent workitem
        end

        #
        # This is the method called when a 'listenable' workitem comes in
        #
        def call (channel, *args)
            #synchronize do

            upon = args[0]

            ldebug { "call() channel : '#{channel}' upon '#{upon}'" }

            return if upon != @upon

            workitem = args[1].dup

            conditional = eval_condition :where, workitem
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

            workitem = merge_workitems @applied_workitem.dup, workitem \
                if @applied_workitem

            #
            # reply or launch nested child expression

            return reply_to_parent(workitem) \
                if raw_children.size < 1
                    #
                    # was just a "blocking listen"

            #parent = @once ? self : nil
            #get_expression_pool.launch_template(
            #    parent,
            #    nil,
            #    @call_count - 1,
            #    @children[0],
            #    workitem,
            #    nil)

            if @once

                # triggering just once

                get_expression_pool.tlaunch_child(
                    self,
                    raw_children.first,
                    @call_count - 1,
                    workitem,
                    true) # registering child

            else

                # triggering multiple times

                get_expression_pool.tlaunch_orphan(
                    self,
                    raw_children.first,
                    @call_count - 1,
                    workitem,
                    true) # registering child (in case of cancel)
            end

            store_itself
            #end
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

                get_participant_map.add_observer @participant_regex, self
            end

            #
            # Expression's job is over, deregister.
            #
            def stop_observing

                get_participant_map.remove_observer self
            end
    end

end

