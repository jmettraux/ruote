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

require 'ruote/receiver/base'
require 'ruote/svc/dispatch_pool'


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

    # Set right before a call to #on_error
    #
    attr_accessor :error

    # Set right before a call to #on_error
    #
    attr_accessor :msg

    # Returns the current workitem if no fei is given.
    # If a fei is given, it will return the applied workitem for that fei
    # (if any).
    #
    # The optional fei is mostly here for backward compatibility (with 2.2.0)
    #
    def workitem(fei=nil)

      return fetch_workitem(fei) if fei

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
    # If a wi_or_fei arg is given, will return the corresponding
    # flow expression. This arg is mostly here for backward compatibility.
    #
    def fexp(wi_or_fei=nil)

      flow_expression(wi_or_fei || fei)
    end

    # Returns the workitem as was applied when the Ruote::ParticipantExpression
    # was reached.
    #
    # If the _fei arg is specified, it will return the corresponding applied
    # workitem. This args is mostly here for backward compatibility.
    #
    def applied_workitem(_fei=nil)

      fetch_workitem(_fei || fei)
    end

    # Up until ruote 2.3.0, the participant name had to be fetched from the
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

    # A shortcut for
    #
    #   fexp.lookup_variable(key)
    #
    def lookup_variable(key)

      fexp.lookup_variable(key)
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
    def re_dispatch(wi=nil, opts=nil)

      wi, opts = [ nil, wi ] if wi.is_a?(Hash) && opts.nil?
      wi ||= workitem()
      opts ||= {}

      wi.h['re_dispatch_count'] = wi.h['re_dispatch_count'].to_s.to_i + 1

      msg = {
        'action' => 'dispatch',
        'fei' => wi.h.fei,
        'workitem' => wi.h,
        'participant_name' => wi.participant_name
      }

      if t = opts[:in] || opts[:at]

        sched_id = @context.storage.put_schedule('at', wi.h.fei, t, msg)

        exp = fexp(wi)
        exp.h['re_dispatch_sched_id'] = sched_id
        exp.try_persist

      else

        @context.storage.put_msg('dispatch', msg)
      end
    end

    # Cancels the scheduled re_dispatch, if any.
    #
    # An example of 'retrying participant' :
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

    #--
    # test methods
    # prefixed with an underscore
    #++

    # Test shortcut, alleviates the need to set the workitem before calling
    # consume / on_workitem.
    #
    def _on_workitem(wi)
      Ruote.participant_send(
        self, [ :on_workitem, :consume ], 'workitem' => wi)
    end
    alias _consume _on_workitem

    # Test shortcut, alleviates the need to set fei and flavour before calling
    # cancel / on_consume.
    #
    def _on_cancel(fei, flavour)
      Ruote.participant_send(
        self, [ :on_cancel, :cancel ], 'fei' => fei, 'flavour' => flavour)
    end
    alias _cancel _on_cancel

    # Test shortcut, alleviates the need to set the workitem before calling
    # on_reply.
    #
    def _on_reply(wi)
      Ruote.participant_send(self, :on_reply, 'workitem' => wi)
    end

    # Test shortcut, alleviates the need to set the workitem before calling
    # accept?
    #
    def _accept?(wi)
      Ruote.participant_send(self, :accept?, 'workitem' => wi)
    end

    # Test shortcut, alleviates the need to set the workitem before calling
    # dont_thread?, do_not_thread? or do_not_thread.
    #
    def _dont_thread?(wi)
      Ruote.participant_send(
        self,
        [ :dont_thread?, :do_not_thread?, :do_not_thread ],
        'workitem' => wi)
    end
    alias _do_not_thread _dont_thread?
    alias _do_not_thread? _dont_thread?

    # Test shortcut, alleviates the need to set the workitem before calling
    # rtimeout.
    #
    def _rtimeout(wi)
      Ruote.participant_send(self, :rtimeout, 'workitem' => wi)
    end

    # Returns true if the underlying participant expression is 'gone' (probably
    # cancelled somehow).
    #
    def is_gone?

      fexp.nil?
    end

    # Returns true if the underlying participant expression is gone or
    # cancelling.
    #
    def is_cancelled?

      if fe = fexp
        return fe.h.state == 'cancelling'
      else
        true
      end
    end

    alias is_canceled? is_cancelled?

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

