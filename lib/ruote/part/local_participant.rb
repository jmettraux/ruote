#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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

    # The engine context, it's a local participant so it knows about the
    # context in which the engine operates...
    #
    attr_accessor :context

    # Usually set right before a call to #on_workitem or #accept?
    #
    attr_writer :workitem

    # Usually set right before a call to #on_cancel or #cancel
    #
    attr_writer :fei

    # Usually set right before a call to #on_cancel or #cancel
    #
    attr_accessor :flavour

    # Returns the current workitem
    #
    # the (_=nil) optional argument is for backward compatibility.
    #
    def workitem(_=nil)

      @workitem ? @workitem : applied_workitem
    end

    # Returns the current fei (Ruote::FlowExpressionId).
    #
    def fei

      @fei ? @fei : @workitem.fei
    end

    # Returns the Ruote::ParticipantExpression that corresponds with this
    # participant.
    #
    # the (_=nil) optional argument is for backward compatibility.
    #
    def fexp(_=nil)

      flow_expression(fei)
    end

    # Returns the workitem as was applied when the Ruote::ParticipantExpression
    # was reached.
    #
    # the (_=nil) optional argument is for backward compatibility.
    #
    def applied_workitem(_=nil)

      Ruote::Workitem.new(fexp.h['applied_workitem'])
    end

    # Up until ruote 2.2.1, the participant name had to be fetched from the
    # workitem. This is a shortcut, it lets you write participant code
    # that look like
    #
    #   def on_workitem
    #     (workitem.fields['supervisors'] || []) << participant_name
    #     reply
    #   end
    #
    def participant_name

      workitem.participant_name
    end

    # Participant implementations call this method when their #on_workitem
    # (#consume) methods are done and they want to hand back the workitem
    # to the engine so that the flow can resume.
    #
    # the (wi=workitem) is mostly for backward compatibility (or for passing a
    # totally different workitem to the engine).
    #
    def reply_to_engine(wi=workitem)

      receive(wi)
    end

    alias reply reply_to_engine

    # Use this method to re_dispatch the workitem.
    #
    # It takes two options :in and :at for "later re_dispatch".
    #
    # Look at the unschedule_re_dispatch method for an example of
    # participant implementation that uses re_dispatch.
    #
    # Without one of those options, the method is a "reject".
    #
    def re_dispatch(wi, opts={})

      opts = wi if wi.is_a?(Hash)
      wi = workitem

      msg = {
        'action' => 'dispatch',
        'fei' => wi.h.fei,
        'workitem' => wi.h,
        'participant_name' => wi.participant_name,
        'rejected' => true
      }

      if t = opts[:in] || opts[:at]

        sched_id = @context.storage.put_schedule('at', wi.h.fei, t, msg)

        exp = fexp
        exp.h['re_dispatch_sched_id'] = sched_id
        exp.try_persist

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
    #     def initialize(opts)
    #       @opts = opts
    #     end
    #
    #     def on_workitem
    #       begin
    #         do_the_job
    #         reply
    #       rescue
    #         re_dispatch(:in => @opts['delay'] || '1s')
    #       end
    #     end
    #
    #     def cancel
    #       unschedule_re_dispatch
    #     end
    #   end
    #
    # Note how unschedule_re_dispatch is used in the cancel method. Warning,
    # this example could loop forever...
    #
    def unschedule_re_dispatch(fei=nil)

      if s = fexp.h['re_dispatch_sched_id']
        @context.storage.delete_schedule(s)
      end
    end

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

    protected

    # Receivers and local participants share the #stash_put and #stash_get
    # methods. The local participant has #put and #get which don't need
    # an initial fei, thus #get and #put deal with the participant
    # expression directly, whereas stash_put and stash_get can point at
    # any expression.
    #
    # 'put' can be called as
    #
    #   put('secret' => 'message', 'to' => 'embassy')
    #     # or
    #   put('secret', 'message')
    #
    def put(key, value=nil)

      stash_put(fei, key, value)
    end

    # See #put
    #
    def get(key=nil)

      stash_get(fei, key)
    end
  end
end

