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

require 'ruote/context'
require 'ruote/engine/process_status'
require 'ruote/receiver/base'


module Ruote

  class Engine

    include ReceiverMixin

    attr_reader :storage
    attr_reader :worker
    attr_reader :context
    attr_reader :variables

    def initialize (worker_or_storage, run=true)

      if worker_or_storage.respond_to?(:storage)

        @worker = worker_or_storage
        @storage = @worker.storage
        @context = @worker.context
        @context.engine = self
      else

        @worker = nil
        @storage = worker_or_storage
        @context = Ruote::Context.new(@storage, self)
      end

      @variables = EngineVariables.new(@storage)

      @worker.run_in_thread if @worker && run
    end

    def launch (process_definition, fields={}, variables={})

      wfid = @context.wfidgen.generate

      @storage.put_msg(
        'launch',
        'wfid' => wfid,
        'tree' => @context.parser.parse(process_definition),
        'workitem' => { 'fields' => fields },
        'variables' => variables)

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
        exp.unpersist_or_raise if exp
      end

      @storage.delete(err.to_h) # remove error

      @storage.put_msg(action, msg) # trigger replay
    end

    # Re-applies an expression (given via its FlowExpressionId).
    #
    # That will cancel the expression and, once the cancel operation is over
    # (all the children have been cancelled), the expression will get
    # re-applied.
    #
    # == options
    #
    # :tree is used to completely change the tree of the expression at re_apply
    #
    #   engine.re_apply(fei, :tree => [ 'participant', { 'ref' => 'bob' }, [] ])
    #
    # :fields is used to replace the fields of the workitem at re_apply
    #
    #   engine.re_apply(fei, :fields => { 'customer' => 'bob' })
    #
    # :merge_in_fields is used to add / override fields
    #
    #   engine.re_apply(fei, :merge_in_fields => { 'customer' => 'bob' })
    #
    def re_apply (fei, opts={})

      @context.storage.put_msg('cancel', 'fei' => fei.to_h, 're_apply' => opts)
    end

    # Returns a ProcessStatus instance describing the current status of
    # a process instance.
    #
    def process (wfid)

      exps = @storage.get_many('expressions', /!#{wfid}$/)
      errs = @storage.get_many('errors', /!#{wfid}$/)

      return nil if exps.empty? && errs.empty?

      ProcessStatus.new(@context, exps, errs)
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
        (by_wfid[err['msg']['fei']['wfid']] ||= [ [], [] ]).last << err
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

    # Loads and parses the process definition at the given path.
    #
    def load_definition (path)

      @context.parser.parse(path)
    end

    # Registers a participant in the engine. Returns the participant instance.
    #
    # Some examples :
    #
    #   require 'ruote/part/hash_participant'
    #   alice = engine.register_participant 'alice', Ruote::HashParticipant
    #     # register an in-memory (hash) store for Alice's workitems
    #
    #   engine.register_participant 'compute_sum' do |wi|
    #     wi.fields['sum'] = wi.fields['articles'].inject(0) do |s, (c, v)|
    #       s + c * v # sum + count * value
    #     end
    #     # a block participant implicitely replies to the engine immediately
    #   end
    #
    #   class MyParticipant
    #     def initialize (name)
    #       @name = name
    #     end
    #     def consume (workitem)
    #       workitem.fields['rocket_name'] = @name
    #       send_to_the_moon(workitem)
    #     end
    #     def cancel (fei, flavour)
    #       # do nothing
    #     end
    #   end
    #   engine.register_participant /^moon-.+/, MyParticipant.new('Saturn-V')
    #
    #
    # == passing a block to a participant
    #
    # Usually only the BlockParticipant cares about being passed a block :
    #
    #   engine.register_participant 'compute_sum' do |workitem|
    #     workitem.fields['kilroy'] = 'was here'
    #   end
    #
    # But it's OK to pass a block to a custom participant :
    #
    #   require 'ruote/part/local_participant'
    #
    #   class MyParticipant
    #     include Ruote::LocalParticipant
    #     def initialize (opts)
    #       @name = opts[:name]
    #       @block = opts[:block]
    #     end
    #     def consume (workitem)
    #       workitem.fields['prestamp'] = Time.now
    #       workitem.fields['author'] = @name
    #       @block.call(workitem)
    #       reply_to_engine(workitem)
    #     end
    #   end
    #
    #   engine.register_participant 'al', MyParticipant, :name => 'toto' do |wi|
    #     wi.fields['nada'] = surf
    #   end
    #
    # The block is available under the :block option.
    #
    def register_participant (regex, participant=nil, opts={}, &block)

      pa = @context.plist.register(regex, participant, opts, block)

      @context.storage.put_msg(
        'participant_registered',
        'regex' => regex.to_s,
        'engine_worker_only' => (pa != nil))

      pa
    end

    # Removes/unregisters a participant from the engine.
    #
    def unregister_participant (name_or_participant)

      re = @context.plist.unregister(name_or_participant)

      raise(ArgumentError.new('participant not found')) unless re

      @context.storage.put_msg(
        'participant_unregistered',
        'regex' => re.to_s)
    end

    # Adds a service locally (will not get propagated to other workers).
    #
    #   tracer = Tracer.new
    #   @engine.add_service('tracer', tracer)
    #
    # or
    #
    #   @engine.add_service('tracer', 'ruote/exp/tracer', 'Ruote::Exp::Tracer')
    #
    # This method returns the service instance it just bound.
    #
    def add_service (name, path_or_instance, classname=nil, opts=nil)

      @context.add_service(name, path_or_instance, classname, opts)
    end

    # Sets a configuration option. Examples:
    #
    #   # allow remote workflow definitions (for subprocesses or when launching
    #   # processes)
    #   @engine.configure('remote_definition_allowed', true)
    #
    #   # allow ruby_eval
    #   @engine.configure('ruby_eval_allowed', true)
    #
    def configure (config_key, value)

      @context[config_key] = value
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

