#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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

require 'ruote/context'
require 'ruote/launchitem'
require 'ruote/engine/process_status'


module Ruote

  class Engine

    require 'ruote/engine/ro_participant'

    attr_reader :storage
    attr_reader :context
    attr_reader :variables

    def initialize (worker_or_storage, run=true)

      if worker_or_storage.respond_to?(:context)

        @storage = worker_or_storage.storage
        @context = worker_or_storage.context
        @context.engine = self

        @context.worker.run_in_thread if run

      else

        @storage = worker_or_storage
        @context = Ruote::EngineContext.new(self)
      end

      @variables = EngineVariables.new(@storage)
    end

    def launch (definition, opts={})

      if definition.is_a?(Launchitem)
        opts[:fields] = definition.fields
        definition = definition.definition
      end

      tree = @context.parser.parse(definition)

      workitem = { 'fields' => opts[:fields] || {} }

      wfid = @context.wfidgen.generate

      @storage.put_msg(
        'launch',
        'wfid' => wfid,
        'tree' => tree,
        'workitem' => workitem,
        'variables' => {})

      wfid
    end

    def cancel_process (wfid)

      @storage.put_msg('cancel_process', 'wfid' => wfid)
    end

    def kill_process (wfid)

      @storage.put_msg('kill_process', 'wfid' => wfid)
    end

    def cancel_expression (fei)

      fei = fei.to_h if fei.respond_to?(:to_h)
      @storage.put_msg('cancel', 'fei' => fei)
    end

    def kill_expression (fei)

      fei = fei.to_h if fei.respond_to?(:to_h)
      @storage.put_msg('cancel', 'fei' => fei, 'flavour' => 'kill')
    end

    # Replays at a given error (hopefully you fixed the cause of the error
    # before replaying...)
    #
    def replay_at_error (err)

      msg = err.msg.dup
      action = msg.delete('action')

      msg['replay_at_error'] = true
        # just an indication

      if msg['tree'] && fei = msg['fei']
        #
        # nukes the expression in case of [re]apply
        #
        exp = Ruote::Exp::FlowExpression.fetch(@context, fei)
        exp.unpersist if exp
      end

      #@storage.delete(err.to_h) # remove error
        #
        # done when the expression gets deleted
        #
        # but
        #
        # is there a case, 5 lines above, where there is no expression
        # to delete ?

      @storage.put_msg(action, msg) # trigger replay
    end

    # Re-applies an expression (given via its FlowExpressionId).
    #
    # That will cancel the expression and, once the cancel operation is over
    # (all the children have been cancelled), the expression will get
    # re-applied.
    #
    def re_apply (fei)

      @context.storage.put_msg('cancel', 'fei' => fei.to_h, 're_apply' => true)
    end

    # Returns a ProcessStatus instance describing the current status of
    # a process instance.
    #
    def process (wfid)

      exps = @storage.get_many('expressions', /#{wfid}$/)

      return nil if exps.size < 1

      ProcessStatus.new(
        @context, exps, @storage.get_many('errors', /#{wfid}$/))
    end

    # Returns an array of ProcessStatus instances.
    #
    # WARNING : this is an expensive operation.
    #
    def processes

      exps = @storage.get_many('expressions')
      errs = @storage.get_many('errors')

      by_wfid = {}

      exps.each do |exp|
        (by_wfid[exp['fei']['wfid']] ||= [ [], [] ]).first << exp
      end
      errs.each do |err|
        (by_wfid[err['fei']['wfid']] ||= [ [], [] ]).last << err
      end

      by_wfid.values.collect { |xs, rs| ProcessStatus.new(@context, xs, rs) }
    end

    def shutdown

      @context.shutdown
    end

    # This method expects there is a logger with a wait_for method in the
    # context, else it will raise an exception.
    #
    # This method is only useful for test/quickstart/examples environments.
    #
    #   engine.wait_for(:alpha)
    #     # will make the current thread block until a workitem is delivered
    #     # to the participant named 'alpha'
    #
    #   engine.wait_for('123432123-9043')
    #     # will make the current thread block until the processed whose
    #     # wfid is given (String) terminates or produces an error.
    #
    #   engine.wait_for(5)
    #     # will make the current thread block until 5 messages have been
    #     # processed on the workqueue...
    #
    def wait_for (item)

      logger = @context['s_logger']

      raise(
        "can't wait_for, there is no logger that responds to that call"
      ) unless logger.respond_to?(:wait_for)

      logger.wait_for(item)
    end
  end

  #
  # A wrapper class giving easy access to engine variables.
  #
  # There is one instance of this class for an Engine instance. It is
  # returned when calling Engine#variables.
  #
  class EngineVariables

    def initialize (storage)

      @storage = storage
    end

    def [] (k)

      @storage.get_engine_variable(k)
    end

    def []= (k, v)

      @storage.put_engine_variable(k, v)
    end
  end
end

