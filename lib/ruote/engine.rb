
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

require 'ruote/context'
require 'ruote/engine/process_status'
require 'ruote/receiver/base'


module Ruote

  #
  # This class holds the 'engine' name, perhaps 'dashboard' would have been
  # a better name. Anyway, the methods here allow to launch processes
  # and to query about their status. There are also methods for fixing
  # issues with stalled processes or processes stuck in errors.
  #
  # NOTE : the methods #launch and #reply are implemented in
  # Ruote::ReceiverMixin (this Engine class has all the methods of a Receiver).
  #
  class Engine

    include ReceiverMixin

    attr_reader :context
    attr_reader :variables

    # Creates an engine using either worker or storage.
    #
    # If a storage instance is given as the first argument, the engine will be
    # able to manage processes (for example, launch and cancel workflows) but
    # will not actually run any workflows.
    #
    # If a worker instance is given as the first argument and the second
    # argument is true, engine will start the worker and will be able to both
    # manage and run workflows.
    #
    # If the second options is set to { :join => true }, the worker wil
    # be started and run in the current thread.
    #
    def initialize (worker_or_storage, opts=true)

      @context = worker_or_storage.context
      @context.engine = self

      @variables = EngineVariables.new(@context.storage)

      if @context.worker
        if opts == true
          @context.worker.run_in_thread
            # runs worker in its own thread
        elsif opts == { :join => true }
          @context.worker.run
            # runs worker in current thread (and doesn't return)
        #else
          # worker is not run
        end
      #else
        # no worker
      end
    end

    # Returns the storage this engine works with passed at engine
    # initialization.
    #
    def storage

      @context.storage
    end

    # Returns the worker nested inside this engine (passed at initialization).
    # Returns nil if this engine is only linked to a storage (and the worker
    # is running somewhere else (hopefully)).
    #
    def worker

      @context.worker
    end

    # Quick note : the implementation of launch is found in the module
    # Ruote::ReceiverMixin that the engine includes.
    #
    # Some processes have to have one and only one instance of themselves
    # running, these are called 'singles' ('singleton' is too object-oriented).
    #
    # When called, this method will check if an instance of the pdef is
    # already running (it uses the process definition name attribute), if
    # yes, it will return without having launched anything. If there is no
    # such process running, it will launch it (and register it).
    #
    # Returns the wfid (workflow instance id) of the running single.
    #
    def launch_single (process_definition, fields={}, variables={})

      tree = @context.reader.read(process_definition)
      name = tree[1]['name'] || (tree[1].find { |k, v| v.nil? } || []).first

      raise ArgumentError.new(
        'process definition is missing a name, cannot launch as single'
      ) unless name

      singles = @context.storage.get('variables', 'singles') || {
        '_id' => 'singles', 'type' => 'variables', 'h' => {}
      }
      wfid, timestamp = singles['h'][name]

      return wfid if wfid && (ps(wfid) || Time.now.to_f - timestamp < 1.0)
        # return wfid if 'singleton' process is already running

      wfid = @context.wfidgen.generate

      singles['h'][name] = [ wfid, Time.now.to_f ]

      r = @context.storage.put(singles)

      return launch_single(tree, fields, variables) unless r.nil?
        #
        # the put failed, back to the start...
        #
        # all this to prevent races between multiple engines,
        # multiple launch_single calls (from different Ruby runtimes)

      # ... green for launch

      @context.storage.put_msg(
        'launch',
        'wfid' => wfid,
        'tree' => tree,
        'workitem' => { 'fields' => fields },
        'variables' => variables)

      wfid
    end

    # Given a process identifier (wfid), cancels this process.
    #
    def cancel_process (wfid)

      @context.storage.put_msg('cancel_process', 'wfid' => wfid)
    end

    # Given a process identifier (wfid), kills this process. Killing is
    # equivalent to cancelling, but when killing, :on_cancel attributes
    # are not triggered.
    #
    def kill_process (wfid)

      @context.storage.put_msg('kill_process', 'wfid' => wfid)
    end

    # Cancels a segment of process instance. Since expressions are nodes in
    # processes instances, cancelling an expression, will cancel the expression
    # and all its children (the segment of process).
    #
    def cancel_expression (fei)

      fei = fei.to_h if fei.respond_to?(:to_h)
      @context.storage.put_msg('cancel', 'fei' => fei)
    end

    # Like #cancel_expression, but :on_cancel attributes (of the expressions)
    # are not triggered.
    #
    def kill_expression (fei)

      fei = fei.to_h if fei.respond_to?(:to_h)
      @context.storage.put_msg('cancel', 'fei' => fei, 'flavour' => 'kill')
    end

    # Given a workitem or a fei, will do a cancel_expression,
    # else it's a wfid and it does a cancel_process.
    #
    def cancel (wi_or_fei_or_wfid)

      target = Ruote.extract_id(wi_or_fei_or_wfid)

      if target.is_a?(String)
        cancel_process(target)
      else
        cancel_expression(target)
      end
    end

    # Given a workitem or a fei, will do a kill_expression,
    # else it's a wfid and it does a kill_process.
    #
    def kill (wi_or_fei_or_wfid)

      target = Ruote.extract_id(wi_or_fei_or_wfid)

      if target.is_a?(String)
        kill_process(target)
      else
        kill_expression(target)
      end
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

      @context.storage.delete(err.to_h) # remove error

      @context.storage.put_msg(action, msg) # trigger replay
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

      list_processes([ wfid ], {}).first
    end

    # Returns an array of ProcessStatus instances.
    #
    # WARNING : this is an expensive operation, but it understands :skip
    # and :limit, so pagination is our friend.
    #
    # Please note, if you're interested only in processes that have errors,
    # Engine#errors is a more efficient means.
    #
    # To simply list the wfids of the currently running, Engine#process_wfids
    # is way cheaper to call.
    #
    def processes (opts={})

      wfids = nil

      if opts.size > 0

        wfids = @context.storage.expression_wfids(opts)

        return wfids.size if opts[:count]
      end

      list_processes(wfids, opts)
    end

    # Returns a list of processes or the process status of a given process
    # instance.
    #
    def ps (wfid=nil)

      wfid == nil ? processes : process(wfid)
    end

    # Returns an array of current errors (hashes)
    #
    # Can be called in two ways :
    #
    #   engine.errors(wfid)
    #
    # and
    #
    #   engine.errors(:skip => 100, :limit => 100)
    #
    def errors (wfid=nil)

      wfid, options = wfid.is_a?(Hash) ? [ nil, wfid ] : [ wfid, {} ]

      errs = wfid.nil? ?
        @context.storage.get_many('errors', nil, options) :
        @context.storage.get_many('errors', wfid)

      return errs if options[:count]

      errs.collect { |err| ProcessError.new(err) }
    end

    # Returns an array of schedules. Those schedules are open structs
    # with various properties, like target, owner, at, put_at, ...
    #
    # Introduced mostly for ruote-kit.
    #
    # Can be called in two ways :
    #
    #   engine.schedules(wfid)
    #
    # and
    #
    #   engine.schedules(:skip => 100, :limit => 100)
    #
    def schedules (wfid=nil)

      wfid, options = wfid.is_a?(Hash) ? [ nil, wfid ] : [ wfid, {} ]

      scheds = wfid.nil? ?
        @context.storage.get_many('schedules', nil, options) :
        @context.storage.get_many('schedules', /!#{wfid}-\d+$/)

      return scheds if options[:count]

      scheds.collect { |sched| Ruote.schedule_to_h(sched) }
    end

    # Returns a [sorted] list of wfids of the process instances currently
    # running in the engine.
    #
    # This operation is substantially less costly than Engine#processes (though
    # the 'how substantially' depends on the storage chosen).
    #
    def process_wfids

      @context.storage.ids('expressions').collect { |sfei|
        sfei.split('!').last
      }.uniq.sort
    end

    # Shuts down the engine, mostly passes the shutdown message to the other
    # services and hope they'll shut down properly.
    #
    def shutdown

      @context.shutdown
    end

    # This method expects there to be a logger with a wait_for method in the
    # context, else it will raise an exception.
    #
    # *WARNING* : wait_for() is meant for environments where there is a unique
    # worker and that worker is nested in this engine. In a multiple worker
    # environment wait_for doesn't see events handled by 'other' workers.
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
    #   engine.wait_for(:empty)
    #     # will return as soon as the engine/storage is empty, ie as soon
    #     # as there are no more processes running in the engine (no more
    #     # expressions placed in the storage)
    #
    # It's OK to wait for multiple wfids :
    #
    #   engine.wait_for('20100612-bezerijozo', '20100612-yakisoba')
    #
    def wait_for (*items)

      logger = @context['s_logger']

      raise(
        "can't wait_for, there is no logger that responds to that call"
      ) unless logger.respond_to?(:wait_for)

      logger.wait_for(items)
    end

    # Joins the worker thread. If this engine has no nested worker, calling
    # this method will simply return immediately.
    #
    def join

      worker.join if worker
    end

    # Loads (and turns into a tree) the process definition at the given path.
    #
    def load_definition (path)

      @context.reader.read(path)
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
    # == 'stateless' participants are preferred over 'stateful' ones
    #
    # Ruote 2.1 is OK with 1 storage and 1+ workers. The workers may be
    # in other ruby runtimes. This implies that if you have registered a
    # participant instance (instead of passing its classname and options),
    # that participant will only run in the worker 'embedded' in the engine
    # where it was registered... Let me rephrase it, participants instantiated
    # at registration time (and that includes block participants) only runs
    # in one worker, always the same.
    #
    # 'stateless' participants, instantiated at each dispatch, are preferred.
    # Any worker can handle them.
    #
    # Block participants are still fine for demos (where the worker is included
    # in the engine (see all the quickstarts). And small engines with 1 worker
    # are not that bad, not everybody is building huge systems).
    #
    # Here is a 'stateless' participant example :
    #
    #   class MyStatelessParticipant
    #     def initialize (opts)
    #       @opts = opts
    #     end
    #     def consume (workitem)
    #       workitem.fields['rocket_name'] = @opts['name']
    #       send_to_the_moon(workitem)
    #     end
    #     def cancel (fei, flavour)
    #       # do nothing
    #     end
    #   end
    #
    #   engine.register_participant(
    #     'moon', MyStatelessParticipant, 'name' => 'saturn5')
    #
    # Remember that the options (the hash that follows the class name), must be
    # serialisable via JSON.
    #
    #
    # == require_path and load_path
    #
    # It's OK to register a participant by passing its full classname as a
    # String.
    #
    #   engine.register_participant(
    #     'auditor', 'AuditParticipant', 'require_path' => 'part/audit.rb')
    #   engine.register_participant(
    #     'auto_decision', 'DecParticipant', 'load_path' => 'part/dec.rb')
    #
    # Note the option load_path / require_path that point to the ruby file
    # containing the participant implementation. 'require' will load and eval
    # the ruby code only once, 'load' each time.
    #
    def register_participant (regex, participant=nil, opts={}, &block)

      pa = @context.plist.register(regex, participant, opts, block)

      @context.storage.put_msg(
        'participant_registered',
        'regex' => regex.to_s,
        'engine_worker_only' => (pa != nil))

      pa
    end

    # A shorter version of #register_participant
    #
    #   engine.register 'alice', MailParticipant, :target => 'alice@example.com'
    #
    # or a block registering mechanism.
    #
    #   engine.register do
    #     alpha 'Participants::Alpha', 'flavour' => 'vanilla'
    #     participant 'bravo', 'Participants::Bravo', :flavour => 'peach'
    #     catchall ParticipantCharlie, 'flavour' => 'coconut'
    #   end
    #
    # Originally implemented in ruote-kit by Torsten Schoenebaum.
    #
    def register (*args, &block)

      if args.size > 0
        register_participant(*args, &block)
      else
        proxy = ParticipantRegistrationProxy.new(self)
        block.arity < 1 ? proxy.instance_eval(&block) : block.call(proxy)
      end
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

    alias :unregister :unregister_participant

    # Returns a list of Ruote::ParticipantEntry instances.
    #
    #   engine.register_participant :alpha, MyParticipant, 'message' => 'hello'
    #
    #   # interrogate participant list
    #   #
    #   list = engine.participant_list
    #   participant = list.first
    #   p participant.regex
    #     # => "^alpha$"
    #   p participant.classname
    #     # => "MyParticipant"
    #   p participant.options
    #     # => {"message"=>"hello"}
    #
    #   # update participant list
    #   #
    #   participant.regex = '^alfred$'
    #   engine.participant_list = list
    #
    def participant_list

      @context.plist.list
    end

    # Accepts a list of Ruote::ParticipantEntry instances.
    #
    # See Engine#participant_list
    #
    def participant_list= (pl)

      @context.plist.list = pl
    end

    # A convenience method for
    #
    #   sp = Ruote::StorageParticipant.new(engine)
    #
    # simply do
    #
    #   sp = engine.storage_participant
    #
    def storage_participant

      @storage_participant ||= Ruote::StorageParticipant.new(self)
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

    # Returns a configuration value.
    #
    #   engine.configure('ruby_eval_allowed', true)
    #
    #   p engine.configuration('ruby_eval_allowed')
    #     # => true
    #
    def configuration (config_key)

      @context[config_key]
    end

    # Returns the process tree that is triggered in case of error.
    #
    # Note that this 'on_error' doesn't trigger if an on_error is defined
    # in the process itself.
    #
    # Returns nil if there is no 'on_error' set.
    #
    def on_error

      @context.storage.get_trackers['trackers']['on_error']['msg']['tree']

    rescue
      nil
    end

    # Returns the process tree that is triggered in case of process termination.
    #
    # Note that a termination process doesn't raise a termination process when
    # it terminates itself.
    #
    # Returns nil if there is no 'on_terminate' set.
    #
    def on_terminate

      @context.storage.get_trackers['trackers']['on_terminate']['msg']['tree']

    rescue
      nil
    end

    # Sets a participant or subprocess to be triggered when an error occurs
    # in a process instance.
    #
    #   engine.on_error = participant_name
    #
    #   engine.on_error = subprocess_name
    #
    #   engine.on_error = Ruote.process_definition do
    #     alpha
    #   end
    #
    # Note that this 'on_error' doesn't trigger if an on_error is defined
    # in the process itself.
    #
    def on_error= (target)

      @context.tracker.add_tracker(
        nil, # do not track a specific wfid
        'error_intercepted', # react on 'error_intercepted' msgs
        'on_error', # the identifier
        nil, # no specific condition
        { 'action' => 'launch',
          'wfid' => 'replace',
          'tree' => target.is_a?(String) ?
            [ 'define', {}, [ [ target, {}, [] ] ] ] : target,
          'workitem' => 'replace',
          'variables' => 'compile' })
    end

    # Sets a participant or a subprocess that is to be launched/called whenever
    # a regular process terminates.
    #
    #   engine.on_terminate = participant_name
    #
    #   engine.on_terminate = subprocess_name
    #
    #   engine.on_terminate = Ruote.define do
    #     alpha
    #     bravo
    #   end
    #
    # Note that a termination process doesn't raise a termination process when
    # it terminates itself.
    #
    # on_terminate processes are not triggered for on_error processes.
    # on_error processes are triggered for on_terminate processes as well.
    #
    def on_terminate= (target)

      @context.tracker.add_tracker(
        nil, # do not track a specific wfid
        'terminated', # react on 'error_intercepted' msgs
        'on_terminate', # the identifier
        nil, # no specific condition
        { 'action' => 'launch',
          'tree' => target.is_a?(String) ?
            [ 'define', {}, [ [ target, {}, [] ] ] ] : target,
          'workitem' => 'replace' })
    end

    # A debug helper :
    #
    #   engine.noisy = true
    #
    # will let the engine (in fact the worker) pour all the details of the
    # executing process instances to STDOUT.
    #
    def noisy= (b)

      @context.logger.noisy = b
    end

    protected

    # Used by #process and #processes
    #
    def list_processes (wfids, opts)

      swfids = wfids ? wfids.collect { |wfid| /!#{wfid}-\d+$/ } : nil

      exps = @context.storage.get_many('expressions', wfids).compact
      swis = @context.storage.get_many('workitems', wfids).compact
      errs = @context.storage.get_many('errors', wfids).compact
      schs = @context.storage.get_many('schedules', swfids).compact
        # some slow storages needs the compaction... couch...

      errs = errs.collect { |err| ProcessError.new(err) }
      schs = schs.collect { |sch| Ruote.schedule_to_h(sch) }

      by_wfid = {}

      exps.each do |exp|
        (by_wfid[exp['fei']['wfid']] ||= [ [], [], [], [] ])[0] << exp
      end
      swis.each do |swi|
        (by_wfid[swi['fei']['wfid']] ||= [ [], [], [], [] ])[1] << swi
      end
      errs.each do |err|
        (by_wfid[err.wfid] ||= [ [], [], [], [] ])[2] << err
      end
      schs.each do |sch|
        (by_wfid[sch['wfid']] ||= [ [], [], [], [] ])[3] << sch
      end

      wfids = if wfids
        wfids
      else
        wfids = by_wfid.keys.sort
        wfids = wfids.reverse if opts[:descending]
        wfids
      end

      wfids.inject([]) { |a, wfid|
        info = by_wfid[wfid]
        a << ProcessStatus.new(@context, *info) if info
        a
      }
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

  #
  # Engine#register uses this proxy when it's passed a block.
  #
  # Originally written by Torsten Schoenebaum for ruote-kit.
  #
  class ParticipantRegistrationProxy

    def initialize (engine)

      @engine = engine
    end

    def participant (name, klass=nil, options={}, &block)

      @engine.register_participant(name, klass, options, &block)
    end

    def catchall (*args)

      klass = args.empty? ? Ruote::StorageParticipant : args.first
      options = args[1] || {}

      participant('.+', klass, options)
    end

    # Maybe a bit audacious...
    #
    def method_missing (method_name, *args)

      participant(method_name, *args)
    end
  end

  # Refines a schedule as found in the ruote storage into something a bit
  # easier to present.
  #
  def self.schedule_to_h (sched)

    h = sched.dup

    h.delete('_rev')
    h.delete('type')
    msg = h.delete('msg')
    owner = h.delete('owner')

    h['wfid'] = owner['wfid']
    h['action'] = msg['action']
    h['type'] = msg['flavour']
    h['owner'] = Ruote::FlowExpressionId.new(owner)
    h['target'] = Ruote::FlowExpressionId.new(msg['fei'])

    h
  end
end

