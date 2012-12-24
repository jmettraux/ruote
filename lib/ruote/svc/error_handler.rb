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


module Ruote

  #
  # For errors occuring when handling errors.
  #
  class MetaError < StandardError

    attr_reader :error

    def initialize(message, error)

      super("#{message}: #{error.to_s}")
      @error = error
    end
  end

  #
  # A ruote service for turning errors into process errors (or letting
  # those error fire any potential :on_error attributes in the process
  # definition).
  #
  # This service is used, by the worker, the dispatch pool and some
  # receivers (like the one in ruote-beanstalk).
  #
  class ErrorHandler

    def initialize(context)

      @context = context
    end

    # As used by the dispatch pool and the worker.
    #
    def msg_handle(msg, err)

      fexp = Ruote::Exp::FlowExpression.fetch(
        @context, msg['fei'] || msg['workitem']['fei']
      ) rescue nil

      handle(msg, fexp, err)
    end

    # Packages the error in a 'raise' msg and places it in the storage,
    # for a worker to pick it up.
    #
    def msg_raise(msg, err)

      fei = msg['fei']
      wfid = msg['wfid'] || msg.fetch('fei', {})['wfid']

      @context.storage.put_msg(
        'raise',
        'fei' => fei,
        'wfid' => wfid,
        'msg' => msg,
        'error' => deflate(err, fei))
    end

    # As used by some receivers (see ruote-beanstalk's receiver).
    #
    # TODO: at some point, merge that with #msg_raise
    #
    def action_handle(action, fei, err)

      fexp = Ruote::Exp::FlowExpression.fetch(@context, fei)

      msg = {
        'action' => action,
        'fei' => fei,
        'participant_name' => fexp.h.participant_name,
        'workitem' => fexp.h.applied_workitem,
        'put_at' => Ruote.now_to_utc_s }

      handle(msg, fexp, err)
    end

    protected

    # Called by msg_handle or action_handle.
    #
    def handle(msg, fexp, err)

      err = RaisedError.new(err) unless err.respond_to?(:backtrace)

      meta = err.is_a?(Ruote::MetaError)

      fei = msg['fei'] || (fexp.h.fei rescue nil)
      wfid = msg['wfid'] || (fei || {})['wfid']

      # on_error ?

      return if ( ! meta) && fexp && fexp.handle_on_error(msg, err)

      # emit 'msg'
      #
      # (this message might get intercepted by a tracker)

      herr = deflate(err, fei, fexp)

      # fill error in the error journal

      @context.storage.put(
        herr.merge(
          'type' => 'errors',
          '_id' => "err_#{Ruote.to_storage_id(fei)}",
          'message' => err.inspect,                     # :-(
          'trace' => (err.backtrace || []).join("\n"),  # :-(
          'msg' => msg)
      ) if fei

      # advertise 'error_intercepted'

      @context.storage.put_msg(
        'error_intercepted',
        'error' => herr, 'wfid' => wfid, 'fei' => fei, 'msg' => msg)

    rescue => e

      raise e unless @context.worker

      @context.worker.send(
        :handle_step_error,
        e,
        { 'action' => 'error_intercepted',
          'error' => deflate(err, fei),
          'fei' => fei,
          'wfid' => wfid,
          'msg' => msg })
    end

    # Returns a serializable hash with all the details of the error.
    #
    def deflate(err, fei, fexp=nil)

      return err unless err.respond_to?(:backtrace)

      fexp ||=
        Ruote::Exp::FlowExpression.dummy('fei' => fei, 'original_tree' => nil)

      fexp.deflate(err)
    end

    # The 'raise' action/msg passes deflated errors. This wrapper class
    # "inflates" them.
    #
    class RaisedError
      def initialize(h)
        @h = h
      end
      def class
        Ruote.constantize(@h['class'])
      end
      def message
        @h['message']
      end
      def backtrace
        @h['trace']
      end
      def to_s
        "raised: #{@h['class']}: #{@h['message']}"
      end
      alias inspect to_s
    end
  end
end

