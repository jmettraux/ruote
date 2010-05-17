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

require 'ruote/receiver/base'


module Ruote

  #
  # Provides methods for 'local' participants.
  #
  # Assumes the class that includes this module has a #context method
  # that points to the worker or engine ruote context.
  #
  # It's "local" because it has access to the ruote storage.
  #
  module LocalParticipant

    include ReceiverMixin
      # the reply_to_engine method is there

    attr_accessor :context

    # Use this method to re_dispatch the workitem.
    #
    # It takes two options :in and :at for "later re_dispatch".
    #
    # Look at the unschedule_re_dispatch method for an example of
    # participant implementation that uses re_dispatch.
    #
    # Without one of those options, the method is a "reject".
    #
    def re_dispatch (workitem, opts={})

      msg = {
        'action' => 'dispatch',
        'fei' => workitem.h.fei,
        'workitem' => workitem.h,
        'participant_name' => workitem.participant_name,
        'rejected' => true
      }

      if t = opts[:in] || opts[:at]

        sched_id = @context.storage.put_schedule('at', workitem.h.fei, t, msg)

        fexp = fetch_flow_expression(workitem)
        fexp.h['re_dispatch_sched_id'] = sched_id
        fexp.try_persist

      else

        @context.storage.put_msg('dispatch', msg)
      end
    end

    # Cancels the scheduled re_dispatch, if any.
    #
    # An example or 'retrying participant' :
    #
    #   class RetryParticipant
    #     include Ruote::LocalParticipant
    #
    #     def initialize (opts)
    #       @opts = opts
    #     end
    #
    #     def consume (workitem)
    #       begin
    #         do_the_job
    #         reply(workitem)
    #       rescue
    #         re_dispatch(workitem, :in => @opts['delay'] || '1s')
    #       end
    #     end
    #
    #     def cancel (fei, flavour)
    #       unschedule_re_dispatch(fei)
    #     end
    #   end
    #
    # Note how unschedule_re_dispatch is used in the cancel method. Warning,
    # this example could loop forever...
    #
    def unschedule_re_dispatch (fei)

      fexp = Ruote::Exp::FlowExpression.fetch(
        @context, Ruote::FlowExpressionId.extract_h(fei))

      if s = fexp.h['re_dispatch_sched_id']
        @context.storage.delete_schedule(s)
      end
    end

    # WARNING : this method is only for 'stateless' participants, ie
    # participants that are registered in the engine by passing their class
    # and a set of options, like in
    #
    #   engine.register_participant 'alpha', MyParticipant, 'info' => 'none'
    #
    # This reject method replaces the workitem in the [internal] message queue
    # of the ruote engine (since it's a local participant, it has access to
    # the storage and it's thus easy).
    # The idea is that another worker will pick up the workitem and
    # do the participant dispatching.
    #
    # This is an advanced technique. It was requested by people who
    # want to have multiple workers and have only certain worker/participants
    # do the handling.
    # Using reject is not the best method, it's probably better to implement
    # this by re-opening the Ruote::Worker class and changing the
    # cannot_handle(msg) method.
    #
    # reject could be useful anyway, not sure now, but one could imagine
    # scenarii where some participants reject workitems temporarily (while
    # the same participant on another worker would accept it).
    #
    # Well, here it is, use with care.
    #
    alias :reject :re_dispatch
  end
end

