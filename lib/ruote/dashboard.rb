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

require 'ruote/context'
require 'ruote/util/ometa'
require 'ruote/receiver/base'
require 'ruote/dboard/mutation'
require 'ruote/dboard/process_status'


module Ruote

  #
  # This class was once named 'Engine', but since ruote 2.x and its introduction
  # of workers, the methods here are those of a "dashboard". The real engine
  # being the set of workers.
  #
  # The methods here allow to launch processes
  # and to query about their status. There are also methods for fixing
  # issues with stalled processes or processes stuck in errors.
  #
  # NOTE : the methods #launch and #reply are implemented in
  # Ruote::ReceiverMixin (this Engine class has all the methods of a Receiver).
  #
  class Dashboard

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
    # If the second options is set to { :join => true }, the worker will
    # be started and run in the current thread (and the initialize method
    # will not return).
    #
    def initialize(worker_or_storage, opts=true)

      @context = worker_or_storage.context
      @context.dashboard = self

      @variables = EngineVariables.new(@context.storage)

      workers = @context.services.select { |ser|
        ser.respond_to?(:run) && ser.respond_to?(:run_in_thread)
      }

      return unless opts && workers.any?

      # let's isolate a worker to join

      worker = if opts.is_a?(Hash) && opts[:join]
        workers.find { |wor| wor.name == 'worker' } || workers.first
      else
        nil
      end

      (workers - Array(worker)).each { |wor| wor.run_in_thread }
        # launch their thread, but let's not join them

      worker.run if worker
        # and let's not return
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

    # A shortcut for engine.context.history
    #
    def history

      @context.history
    end

    # A shortcut for engine.context.logger
    #
    def logger

      @context.logger
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
    def launch_single(process_definition, fields={}, variables={}, root_stash=nil)

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

      return launch_single(tree, fields, variables, root_stash) unless r.nil?
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
        'variables' => variables,
        'stash' => root_stash)

      wfid
    end

    # Given a flow expression id, locates the corresponding ruote
    # expression and attaches a subprocess to it.
    #
    # Accepts the fei as a Hash or as a FlowExpressionId instance.
    #
    # By default, the workitem of the expression you attach to provides
    # the initial workitem for the attached branch. By using the
    # :fields/:workitem or :merge_fields options, one can change that.
    #
    # Returns the fei of the attached [root] expression
    # (as a FlowExpressionId instance).
    #
    def attach(fei_or_fe, definition, opts={})

      fe = Ruote.extract_fexp(@context, fei_or_fe).h
      fei = fe['fei']

      cfei = fei.merge(
        'expid' => "#{fei['expid']}_0",
        'subid' => Ruote.generate_subid(fei.inspect))

      tree = @context.reader.read(definition)
      tree[0] = 'sequence'

      fields = fe['applied_workitem']['fields']
      if fs = opts[:fields] || opts[:workitem]
        fields = fs
      elsif fs = opts[:merge_fields]
        fields.merge!(fs)
      end

      @context.storage.put_msg(
        'launch', # "apply" is OK, but "launch" stands out better
        'parent_id' => fei,
        'fei' => cfei,
        'tree' => tree,
        'workitem' => { 'fields' => fields },
        'attached' => true)

      Ruote::FlowExpressionId.new(cfei)
    end

    # Given a workitem or a fei, will do a cancel_expression,
    # else it's a wfid and it does a cancel_process.
    #
    # == A note about opts
    #
    # They will get passed as is in the underlying 'msg',
    # it can be useful to flag the message for historical purposes as in
    #
    #   dashboard.cancel(wfid, 'reason' => 'cleanup', 'user' => current_user)
    #
    def cancel(wi_or_fei_or_wfid, opts={})

      do_misc('cancel', wi_or_fei_or_wfid, opts)
    end

    alias cancel_process cancel
    alias cancel_expression cancel

    # Given a workitem or a fei, will do a kill_expression,
    # else it's a wfid and it does a kill_process.
    #
    # (also see notes about opts for #cancel)
    #
    def kill(wi_or_fei_or_wfid, opts={})

      do_misc('cancel', wi_or_fei_or_wfid, opts.merge('flavour' => 'kill'))
    end

    alias kill_process kill
    alias kill_expression kill

    # Removes a process by removing all its schedules, expressions, errors,
    # workitems and trackers.
    #
    # Warning: will not trigger any cancel behaviours at all, just removes
    # the process.
    #
    def remove_process(wfid)

      @context.storage.remove_process(wfid)
    end

    # Given a wfid, will [attempt to] pause the corresponding process instance.
    # Given an expression id (fei) will [attempt to] pause the expression
    # and its children.
    #
    # The only known option for now is :breakpoint => true, which lets
    # the engine only pause the targetted expression.
    #
    #
    # == fei and :breakpoint => true
    #
    # By default, pausing an expression will pause that expression and
    # all its children.
    #
    #   engine.pause(fei, :breakpoint => true)
    #
    # will only flag as paused the given fei. When the children of that
    # expression will reply to it, the execution for this branch of the
    # process will stop, much like a break point.
    #
    def pause(wi_or_fei_or_wfid, opts={})

      opts = Ruote.keys_to_s(opts)

      raise ArgumentError.new(
        ':breakpoint option only valid when passing a workitem or a fei'
      ) if opts['breakpoint'] and wi_or_fei_or_wfid.is_a?(String)

      do_misc('pause', wi_or_fei_or_wfid, opts)
    end

    # Given a wfid will [attempt to] resume the process instance.
    # Given an expression id (fei) will [attempt to] to resume the expression
    # and its children.
    #
    # Note : this is supposed to be called on paused expressions / instances,
    # this is NOT meant to be called to unstuck / unhang a process.
    #
    # == resume(wfid, :anyway => true)
    #
    # Resuming a process instance is equivalent to calling resume on its
    # root expression. If the root is not paused itself, this will have no
    # effect.
    #
    #   dashboard.resume(wfid, :anyway => true)
    #
    # will make sure to call resume on each of the paused branch within the
    # process instance (tree), effectively resuming the whole process.
    #
    def resume(wi_or_fei_or_wfid, opts={})

      do_misc('resume', wi_or_fei_or_wfid, opts)
    end

    # Replays at a given error (hopefully the cause of the error got fixed
    # before replaying...)
    #
    def replay_at_error(err)

      err = error(err) unless err.is_a?(Ruote::ProcessError)

      msg = err.msg.dup

      if tree = msg['tree']
        #
        # as soon as there is a tree, it means it's a re_apply

        re_apply(
          msg['fei'],
          'tree' => tree,
          'replay_at_error' => true,
          'workitem' => msg['workitem'])

      else

        action = msg.delete('action')

        msg['replay_at_error'] = true
          # just an indication

        @context.storage.delete(err.to_h) # remove error
        @context.storage.put_msg(action, msg) # trigger replay
      end
    end

    # Re-applies an expression (given via its FlowExpressionId).
    #
    # That will cancel the expression and, once the cancel operation is over
    # (all the children have been cancelled), the expression will get
    # re-applied.
    #
    # The fei parameter may be a hash, a Ruote::FlowExpressionId instance,
    # a Ruote::Workitem instance or a sid string.
    #
    # == options
    #
    # :tree is used to completely change the tree of the expression at re_apply
    #
    #   dashboard.re_apply(
    #     fei, :tree => [ 'participant', { 'ref' => 'bob' }, [] ])
    #
    # :fields is used to replace the fields of the workitem at re_apply
    #
    #   dashboard.re_apply(
    #     fei, :fields => { 'customer' => 'bob' })
    #
    # :workitem is ok too
    #
    #   dashboard.re_apply(
    #     fei, :workitem => { 'fields' => { 'customer' => 'bob' } })
    #
    # :merge_in_fields is used to add / override fields
    #
    #   dashboard.re_apply(
    #     fei, :merge_in_fields => { 'customer' => 'bob' })
    #
    def re_apply(fei, opts={})

      @context.storage.put_msg(
        'cancel',
        'fei' => FlowExpressionId.extract_h(fei),
        're_apply' => Ruote.keys_to_s(opts))
    end

    # Returns a Mutation instance listing all the operations necessary
    # to transform the current tree of the process (wfid) into
    # the given definition tree (pdef).
    #
    # See also #apply_mutation
    #
    def compute_mutation(wfid, pdef)

      Mutation.new(self, wfid, @context.reader.read(pdef))
    end

    # Computes mutation and immediately applies it...
    #
    # See #compute_mutation
    #
    # Return the mutation instance (forensic?)
    #
    def apply_mutation(wfid, pdef)

      Mutation.new(self, wfid, @context.reader.read(pdef)).apply
    end

    # This method re_apply all the leaves of a process instance. It's meant
    # to be used against stalled workflows to give them back the spark of
    # life.
    #
    # Stalled workflows can happen when msgs get lost. It also happens with
    # some storage implementations where msgs are stored differently from
    # expressions and co.
    #
    # By default, it doesn't re_apply leaves that are in error. If the
    # 'errors_too' option is set to true, it will re_apply leaves in error
    # as well. For example:
    #
    #   $dashboard.respark(wfid, 'errors_too' => true)
    #
    def respark(wfid, opts={})

      @context.storage.put_msg(
        'respark',
        'wfid' => wfid,
        'respark' => Ruote.keys_to_s(opts))
    end

    # Returns a ProcessStatus instance describing the current status of
    # a process instance.
    #
    def process(wfid)

      ProcessStatus.fetch(@context, [ wfid ], {}).first
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
    def processes(opts={})

      wfids = @context.storage.expression_wfids(opts)

      opts[:count] ? wfids.size : ProcessStatus.fetch(@context, wfids, opts)
    end

    # Returns a list of processes or the process status of a given process
    # instance.
    #
    def ps(wfid=nil)

      wfid == nil ? processes : process(wfid)
    end

    # Returns an array of current errors (hashes)
    #
    # Can be called in two ways :
    #
    #   dashboard.errors(wfid)
    #
    # and
    #
    #   dashboard.errors(:skip => 100, :limit => 100)
    #
    def errors(wfid=nil)

      wfid, options = wfid.is_a?(Hash) ? [ nil, wfid ] : [ wfid, {} ]

      errs = wfid.nil? ?
        @context.storage.get_many('errors', nil, options) :
        @context.storage.get_many('errors', wfid)

      return errs if options[:count]

      errs.collect { |err| ProcessError.new(err) }
    end

    # Given a workitem or a fei (or a String version of a fei), returns
    # the corresponding error (or nil if there is no other).
    #
    def error(wi_or_fei)

      fei = Ruote.extract_fei(wi_or_fei)
      err = @context.storage.get('errors', "err_#{fei.sid}")

      err ? ProcessError.new(err) : nil
    end

    # Returns an array of schedules. Those schedules are open structs
    # with various properties, like target, owner, at, put_at, ...
    #
    # Introduced mostly for ruote-kit.
    #
    # Can be called in two ways :
    #
    #   dashboard.schedules(wfid)
    #
    # and
    #
    #   dashboard.schedules(:skip => 100, :limit => 100)
    #
    def schedules(wfid=nil)

      wfid, options = wfid.is_a?(Hash) ? [ nil, wfid ] : [ wfid, {} ]

      scheds = wfid.nil? ?
        @context.storage.get_many('schedules', nil, options) :
        @context.storage.get_many('schedules', /!#{wfid}-\d+$/)

      return scheds if options[:count]

      scheds.collect { |s| Ruote.schedule_to_h(s) }.sort_by { |s| s['wfid'] }
    end

    # Returns a [sorted] list of wfids of the process instances currently
    # running in the engine.
    #
    # This operation is substantially less costly than Engine#processes (though
    # the 'how substantially' depends on the storage chosen).
    #
    def process_ids

      @context.storage.expression_wfids({})
    end

    alias process_wfids process_ids

    # Warning : expensive operation.
    #
    # Leftovers are workitems, errors and schedules belonging to process
    # instances for which there are no more expressions left.
    #
    # Better delete them or investigate why they are left here.
    #
    # The result is a list of documents (hashes) as found in the storage. Each
    # of them might represent a workitem, an error or a schedule.
    #
    # If you want to delete one of them you can do
    #
    #   dashboard.storage.delete(doc)
    #
    def leftovers

      wfids = @context.storage.expression_wfids({})

      wis = @context.storage.get_many('workitems').compact
      ers = @context.storage.get_many('errors').compact
      scs = @context.storage.get_many('schedules').compact
        # some slow storages need the compaction... [c]ouch...

      (wis + ers + scs).reject { |doc| wfids.include?(doc['fei']['wfid']) }
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
    # *WARNING*: #wait_for() is meant for environments where there is a unique
    # worker and that worker is nested in this engine. In a multiple worker
    # environment wait_for doesn't see events handled by 'other' workers.
    #
    # This method is only useful for test/quickstart/examples environments.
    #
    #   dashboard.wait_for(:alpha)
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
    #   engine.wait_for('terminated')
    #     # will return as soon as any process has a 'terminated' event.
    #
    # It's OK to wait for multiple wfids:
    #
    #   engine.wait_for('20100612-bezerijozo', '20100612-yakisoba')
    #
    # If one needs to wait for something else than a wfid but needs to break
    # in case of error:
    #
    #   engine.wait_for(:alpha, :or_error)
    #
    #
    # == ruote 2.3.0 and wait_for(event)
    #
    # Ruote 2.3.0 introduced the ability to wait for an event given its name.
    # Here is a quick list of event names and a their description:
    #
    # * 'launch' - [sub]process launch
    # * 'terminated' - process terminated
    # * 'ceased' - orphan process terminated
    # * 'apply' - expression application
    # * 'reply' - expression reply
    # * 'dispatched' - emitted workitem towards participant
    # * 'receive' - received workitem from participant
    # * 'pause' - pause order
    # * 'resume' - pause order
    # * 'dispatch_cancel' - emitting a cancel order to a participant
    # * 'dispatch_pause' - emitting a pause order to a participant
    # * 'dispatch_resume' - emitting a resume order to a participant
    #
    # Names that are past participles are for notification events, while
    # plain verbs are for action events. Most of the time, a notitication
    # is emitted has the result of an action event, workers don't take any
    # action on them, but services that are listening to the ruote activity
    # might want to do something about them.
    #
    #
    # == ruote 2.3.0 and wait_for(hash)
    #
    # For more precise testing, wait_for accepts hashes, for example:
    #
    #   r = dashboard.wait_for('action' => 'apply', 'exp_name' => 'wait')
    #
    # will block until a wait expression is applied.
    #
    # If you know ruote msgs, you can pinpoint at will:
    #
    #   r = dashboard.wait_for(
    #     'action' => 'apply',
    #     'exp_name' => 'wait',
    #     'fei.wfid' => wfid)
    #
    # == what wait_for returns
    #
    # #wait_for returns the intercepted event. It's useful when testing/
    # spec'ing, as in:
    #
    #   it 'completes successfully' do
    #
    #     definition = Ruote.define :on_error => 'charly' do
    #       alpha
    #       bravo
    #     end
    #
    #     wfid = @board.launch(definition)
    #
    #     r = @board.wait_for(wfid)
    #       # wait until process terminates or hits an error
    #
    #     r['workitem'].should_not == nil
    #     r['workitem']['fields']['alpha'].should == 'was here'
    #     r['workitem']['fields']['bravo'].should == 'was here'
    #     r['workitem']['fields']['charly'].should == nil
    #   end
    #
    # == :timeout option
    #
    # One can pass a timeout value in seconds for the #wait_for call, as in:
    #
    #   dashboard.wait_for(wfid, :timeout => 5 * 60)
    #
    # The default timeout is 60 (seconds). A nil or negative timeout disables
    # the timeout.
    #
    def wait_for(*items)

      opts = (items.size > 1 && items.last.is_a?(Hash)) ? items.pop : {}

      @context.logger.wait_for(items, opts)
    end

    # Joins the worker thread. If this engine has no nested worker, calling
    # this method will simply return immediately.
    #
    def join

      worker.join if worker
    end

    # Loads (and turns into a tree) the process definition at the given path.
    #
    def load_definition(path)

      @context.reader.read(path)
    end

    # Registers a participant in the engine.
    #
    # Takes the form
    #
    #   dashboard.register_participant name_or_regex, klass, opts={}
    #
    # With the form
    #
    #   dashboard.register_participant name_or_regex do |workitem|
    #     # ...
    #   end
    #
    # A BlockParticipant is automatically created.
    #
    #
    # == name or regex
    #
    # When registering participants, strings or regexes are accepted. Behind
    # the scenes, a regex is kept.
    #
    # Passing a string like "alain" will get ruote to automatically turn it
    # into the following regex : /^alain$/.
    #
    # For finer control over this, pass a regex directly
    #
    #   dashboard.register_participant /^user-/, MyParticipant
    #     # will match all workitems whose participant name starts with "user-"
    #
    #
    # == some examples
    #
    #   dashboard.register_participant 'compute_sum' do |wi|
    #     wi.fields['sum'] = wi.fields['articles'].inject(0) do |s, (c, v)|
    #       s + c * v # sum + count * value
    #     end
    #     # a block participant implicitely replies to the engine immediately
    #   end
    #
    #   class MyParticipant
    #     def initialize(opts)
    #       @name = opts['name']
    #     end
    #     def on_workitem
    #       workitem.fields['rocket_name'] = @name
    #       send_to_the_moon(workitem)
    #     end
    #     def on_cancel
    #       # do nothing
    #     end
    #   end
    #
    #   dashboard.register_participant(
    #     /^moon-.+/, MyParticipant, 'name' => 'Saturn-V')
    #
    #   # computing the total for a invoice being passed in the workitem.
    #   #
    #   class TotalParticipant
    #     include Ruote::LocalParticipant
    #
    #     def on_workitem
    #       workitem['total'] = workitem.fields['items'].inject(0.0) { |t, item|
    #         t + item['count'] * PricingService.lookup(item['id'])
    #       }
    #       reply
    #     end
    #
    #     def on_cancel
    #     end
    #   end
    #   dashboard.register_participant 'total', TotalParticipant
    #
    # Remember that the options (the hash that follows the class name), must be
    # serializable via JSON.
    #
    #
    # == require_path and load_path
    #
    # It's OK to register a participant by passing its full classname as a
    # String.
    #
    #   dashboard.register_participant(
    #     'auditor', 'AuditParticipant', 'require_path' => 'part/audit.rb')
    #   dashboard.register_participant(
    #     'auto_decision', 'DecParticipant', 'load_path' => 'part/dec.rb')
    #
    # Note the option load_path / require_path that point to the ruby file
    # containing the participant implementation. 'require' will load and eval
    # the ruby code only once, 'load' each time.
    #
    #
    # == :override => false
    #
    # By default, when registering a participant, if this results in a regex
    # that is already used, the previously registered participant gets
    # unregistered.
    #
    #   dashboard.register_participant 'alpha', AaParticipant
    #   dashboard.register_participant 'alpha', BbParticipant, :override => false
    #
    # This can be useful when the #accept? method of participants are in use.
    #
    # Note that using the #register(&block) method, :override => false is
    # automatically enforced.
    #
    #   dashboard.register do
    #     alpha AaParticipant
    #     alpha BbParticipant
    #   end
    #
    #
    # == :position / :pos => 'last' / 'first' / 'before' / 'after' / 'over'
    #
    # One can specify the position where the participant should be inserted
    # in the participant list.
    #
    #   dashboard.register_participant 'auditor', AuditParticipant, :pos => 'last'
    #
    # * last : it's the default, places the participant at the end of the list
    # * first : top of the list
    # * before : implies :override => false, places before the existing
    #   participant with the same regex
    # * after : implies :override => false, places after the last existing
    #   participant with the same regex
    # * over : overrides in the same position (while the regular, default
    #   overide removes and then places the new participant at the end of
    #   the list)
    #
    def register_participant(regex, participant=nil, opts={}, &block)

      if participant.is_a?(Hash)
        opts = participant
        participant = nil
      end

      pa = @context.plist.register(regex, participant, opts, block)

      @context.storage.put_msg(
        'participant_registered',
        'regex' => regex.is_a?(Regexp) ? regex.inspect : regex.to_s)

      pa
    end

    # A shorter version of #register_participant
    #
    #   dashboard.register 'alice', MailParticipant, :target => 'alice@example.com'
    #
    # or a block registering mechanism.
    #
    #   dashboard.register do
    #     alpha 'Participants::Alpha', 'flavour' => 'vanilla'
    #     participant 'bravo', 'Participants::Bravo', :flavour => 'peach'
    #     catchall ParticipantCharlie, 'flavour' => 'coconut'
    #   end
    #
    # Originally implemented in ruote-kit by Torsten Schoenebaum.
    #
    # == registration in block and :clear
    #
    # By default, when registering multiple participants in block, ruote
    # considers you're wiping the participant list and re-adding them all.
    #
    # You can prevent the clearing by stating :clear => false like in :
    #
    #   dashboard.register :clear => false do
    #     alpha 'Participants::Alpha', 'flavour' => 'vanilla'
    #     participant 'bravo', 'Participants::Bravo', :flavour => 'peach'
    #     catchall ParticipantCharlie, 'flavour' => 'coconut'
    #   end
    #
    def register(*args, &block)

      clear = args.first.is_a?(Hash) ? args.pop[:clear] : true

      if args.size > 0
        register_participant(*args, &block)
      else
        proxy = ParticipantRegistrationProxy.new(self, clear)
        block.arity < 1 ? proxy.instance_eval(&block) : block.call(proxy)
        proxy._flush
      end
    end

    # Removes/unregisters a participant from the engine.
    #
    def unregister_participant(name_or_participant)

      re = @context.plist.unregister(name_or_participant)

      raise(ArgumentError.new('participant not found')) unless re

      @context.storage.put_msg(
        'participant_unregistered',
        'regex' => re.to_s)
    end

    alias :unregister :unregister_participant

    # Returns a list of Ruote::ParticipantEntry instances.
    #
    #   dashboard.register_participant :alpha, MyParticipant, 'message' => 'hello'
    #
    #   # interrogate participant list
    #   #
    #   list = dashboard.participant_list
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
    #   dashboard.participant_list = list
    #
    def participant_list

      @context.plist.list
    end

    # Accepts a list of Ruote::ParticipantEntry instances or a list of
    # [ regex, [ classname, opts ] ] arrays.
    #
    # See Engine#participant_list
    #
    # Some examples :
    #
    #   dashboard.participant_list = [
    #     [ '^charly$', [ 'Ruote::StorageParticipant', {} ] ],
    #     [ '.+', [ 'MyDefaultParticipant', { 'default' => true } ]
    #   ]
    #
    # This method writes the participant list in one go, it might be easier to
    # use than to register participant one by ones.
    #
    def participant_list=(pl)

      @context.plist.list = pl
    end

    # A convenience method for
    #
    #   sp = Ruote::StorageParticipant.new(dashboard)
    #
    # simply do
    #
    #   sp = dashboard.storage_participant
    #
    def storage_participant

      @storage_participant ||= Ruote::StorageParticipant.new(self)
    end

    # #worklist or #storage_participant
    #
    alias worklist storage_participant

    # Returns an instance of the participant registered under the given name.
    # Returns nil if there is no participant registered for that name.
    #
    def participant(name)

      @context.plist.lookup(name.to_s, nil)
    end

    # Adds a service locally (will not get propagated to other workers).
    #
    #   tracer = Tracer.new
    #   @dashboard.add_service('tracer', tracer)
    #
    # or
    #
    #   @dashboard.add_service(
    #     'tracer', 'ruote/exp/tracer', 'Ruote::Exp::Tracer')
    #
    # This method returns the service instance it just bound.
    #
    def add_service(name, path_or_instance, classname=nil, opts=nil)

      @context.add_service(name, path_or_instance, classname, opts)
    end

    # Sets a configuration option. Examples:
    #
    #   # allow remote workflow definitions (for subprocesses or when launching
    #   # processes)
    #   @dashboard.configure('remote_definition_allowed', true)
    #
    #   # allow ruby_eval
    #   @dashboard.configure('ruby_eval_allowed', true)
    #
    def configure(config_key, value)

      @context[config_key] = value
    end

    # Returns a configuration value.
    #
    #   dashboard.configure('ruby_eval_allowed', true)
    #
    #   p dashboard.configuration('ruby_eval_allowed')
    #     # => true
    #
    def configuration(config_key)

      @context[config_key]
    end

    # Returns the hash containing info about each worker connected to the
    # storage.
    #
    def worker_info

      (@context.storage.get('variables', 'workers') || {})['workers']
    end

    # Returns the state the workers are supposed to be in right now.
    # It's usually 'running', but it could be 'stopped' or 'paused'.
    #
    def worker_state

      doc =
        @context.storage.get('variables', 'worker') ||
        { 'type' => 'variables', '_id' => 'worker', 'state' => 'running' }

      doc['state']
    end

    WORKER_STATES = %w[ running stopped paused ]

    # Sets the [desired] worker state. The workers will check that target
    # state at their next beat and switch to it.
    #
    # Setting the state to 'stopped' will force the workers to stop as soon
    # as they notice the new state.
    #
    # Setting the state to 'paused' will force the workers to pause. They
    # will not process msgs until the state is set back to 'running'.
    #
    # By default the [engine] option 'worker_state_enabled' is not set, so
    # calling this method will result in a error, unless 'worker_state_enabled'
    # was set to true when the storage was initialized.
    #
    def worker_state=(state)

      raise RuntimeError.new(
        "'worker_state_enabled' is not set, cannot change state"
      ) unless @context['worker_state_enabled']

      state = state.to_s

      raise ArgumentError.new(
        "#{state.inspect} not in #{WORKER_STATES.inspect}"
      ) unless WORKER_STATES.include?(state)

      doc =
        @context.storage.get('variables', 'worker') ||
        { 'type' => 'variables', '_id' => 'worker', 'state' => 'running' }

      doc['state'] = state

      @context.storage.put(doc) && worker_state=(state)
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
    #   dashboard.on_error = participant_name
    #
    #   dashboard.on_error = subprocess_name
    #
    #   dashboard.on_error = Ruote.process_definition do
    #     alpha
    #   end
    #
    # Note that this 'on_error' doesn't trigger if an on_error is defined
    # in the process itself.
    #
    def on_error=(target)

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
    #   dashboard.on_terminate = participant_name
    #
    #   dashboard.on_terminate = subprocess_name
    #
    #   dashboard.on_terminate = Ruote.define do
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
    def on_terminate=(target)

      msg = {
        'action' => 'launch',
        'tree' => target.is_a?(String) ?
          [ 'define', {}, [ [ target, {}, [] ] ] ] : target,
        'workitem' => 'replace' }

      @context.tracker.add_tracker(
        nil,             # do not track a specific wfid
        'terminated',    # react on 'error_intercepted' msgs
        'on_terminate',  # the identifier
        nil,             # no specific condition
        msg)             # the message that gets triggered
    end

    # /!\ warning: advanced method.
    #
    # Adds a tracker to the ruote engine.
    #
    # === Arguments
    #
    # * wfid:
    #   When nil will track any workflow execution, when set will only
    #   react on msgs for the given wfid.
    # * action:
    #   A string like "apply", "reply" or "receive", the action being tracked
    #   May begin with a "pre_" prefix.
    # * tracker_id:
    #   When nil, ruote chooses a tracker_id, else its the unique identifier
    #   for the new tracker.
    # * conditions:
    #   A Hash of keys pointing to arrays of expected values.
    #   For example { 'tree.0' ~=> [ 'alfred', 'knuth' ] } will trigger
    #   if the first element of msg['tree'] equals alfred or knuth.
    # * msg:
    #   The msg to place in the msg queue if the tracker matches the msg,
    #   the reaction.
    #
    # Returns the tracker_id.
    #
    def add_tracker(wfid, action, tracker_id, conditions, msg)

      @context.tracker.add_tracker(wfid, action, tracker_id, conditions, msg)
    end

    # /!\ warning: advanced method.
    #
    # Removes a tracker from the ruote system.
    #
    # The first arg is a FlowExpressionId, in its instance form, hash form or
    # shortened (sid) string form. It can also be any string (any tracker id).
    #
    # The second arg is optional, it's a wfid. It's useful for some storage
    # implementations (like ruote-swf) and helps determine how to grab
    # the tracker list. Most of the ruote deployments don't need that arg set.
    #
    def remove_tracker(fei_sid_or_id, wfid=nil)

      @context.tracker.remove_tracker(fei_sid_or_id, wfid)
    end

    # Returns a hash { tracker_id => tracker_hash } enumerating all
    # the trackers in the ruote system.
    #
    def get_trackers(wfid=nil)

      @context.storage.get_trackers(wfid)['trackers']
    end

    # A debug helper :
    #
    #   dashboard.noisy = true
    #
    # will let the dashboard (in fact the worker) pour all the details of the
    # executing process instances to STDOUT.
    #
    def noisy=(b)

      @context.logger.noisy = b
    end

    # Warning: advanced method.
    #
    # Currently only used by mutations.
    #
    def update_expression(fei, opts)

      fei = Ruote.extract_fei(fei)
      fexp = Ruote::Exp::FlowExpression::fetch(@context, fei)

      raise ArgumentError.new(
        "no expression found with fei #{fei.sid}"
      ) unless fexp

      if t = opts[:tree]
        fexp.h.updated_tree = opts[:tree]
      end

      r = @context.storage.put(fexp.h)

      raise ArgumentError.new(
        "expression #{fei.sid} is gone"
      ) if r == true

      return update_expression(fei, opts) unless r.nil?
    end

    protected

    # Used by #pause and #resume.
    #
    def do_misc(action, wi_or_fei_or_wfid, opts)

      opts = Ruote.keys_to_s(opts)

      target = Ruote.extract_id(wi_or_fei_or_wfid)

      if action == 'resume' && opts['anyway']
        #
        # determines the roots of the branches that are paused
        # sends the resume message to them.

        exps = ps(target).expressions.select { |fexp| fexp.state == 'paused' }
        feis = exps.collect { |fexp| fexp.fei }

        roots = exps.inject([]) { |a, fexp|
          a << fexp.fei.h unless feis.include?(fexp.parent_id)
          a
        }

        roots.each { |fei| @context.storage.put_msg('resume', 'fei' => fei) }

      elsif target.is_a?(String)
        #
        # action targets a process instance (a string wfid)

        @context.storage.put_msg(
          "#{action}_process", opts.merge('wfid' => target))

      else

        @context.storage.put_msg(
          action, opts.merge('fei' => target))
      end
    end
  end

  #
  # A wrapper class giving easy access to engine variables.
  #
  # There is one instance of this class for an Engine instance. It is
  # returned when calling Engine#variables.
  #
  class EngineVariables

    def initialize(storage)

      @storage = storage
    end

    def [](k)

      @storage.get_engine_variable(k)
    end

    def []=(k, v)

      @storage.put_engine_variable(k, v)
    end
  end

  #
  # Engine#register uses this proxy when it's passed a block.
  #
  # Originally written by Torsten Schoenebaum for ruote-kit.
  #
  class ParticipantRegistrationProxy < Ruote::BlankSlate

    def initialize(dashboard, clear)

      @dashboard = dashboard

      @dashboard.context.plist.clear if clear

      @list = clear ? [] : nil
    end

    def participant(name, klass=nil, options={}, &block)

      if @list

        @list <<
          @dashboard.context.plist.to_entry(name, klass, options, block)

      else

        @dashboard.register_participant(
          name, klass, options.merge!(:override => false), &block)
      end
    end

    def catchall(*args)

      klass = args.empty? ? Ruote::StorageParticipant : args.first
      options = args[1] || {}

      participant('.+', klass, options)
    end

    alias catch_all catchall

    # Maybe a bit audacious...
    #
    def method_missing(method_name, *args, &block)

      participant(method_name, *args, &block)
    end

    def _flush

      @dashboard.participant_list = @list if @list
    end
  end

  # Refines a schedule as found in the ruote storage into something a bit
  # easier to present.
  #
  def self.schedule_to_h(sched)

    h = sched.dup

    class << h; attr_accessor :h; end
    h.h = sched
      #
      # for the sake of ProcessStatus#to_h

    h.delete('_rev')
    h.delete('type')
    msg = h.delete('msg')
    owner = h.delete('owner')

    h['wfid'] = owner['wfid']
    h['action'] = msg['action']
    h['type'] = msg['flavour']
    h['owner'] = Ruote::FlowExpressionId.new(owner)

    h['target'] = Ruote::FlowExpressionId.new(msg['fei']) if msg['fei']

    h
  end
end

