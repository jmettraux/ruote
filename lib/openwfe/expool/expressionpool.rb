#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/utils'
require 'openwfe/service'
require 'openwfe/logging'
require 'openwfe/omixins'
require 'openwfe/rudefinitions'
require 'openwfe/flowexpressionid'
require 'openwfe/util/observable'
require 'openwfe/expool/errors'
require 'openwfe/expool/expool_pause_methods'
require 'openwfe/expool/representation'
require 'openwfe/expressions/environment'
require 'openwfe/expressions/raw'


module OpenWFE

  #
  # The ExpressionPool stores expressions (pieces of workflow instance).
  # It's the core of the workflow engine.
  # It relies on an expression storage for actual persistence of the
  # expressions.
  #
  class ExpressionPool

    include ServiceMixin
    include OwfeServiceLocator
    include OwfeObservable
    include FeiMixin

    include ExpoolPauseMethods

    # The hash containing the wfid of the process instances currently
    # paused (a cache).
    #
    attr_reader :paused_instances

    # The constructor for the expression pool.
    #
    def initialize (service_name, application_context)

      super()

      service_init service_name, application_context

      @paused_instances = {}

      @observers = {}

      @stopped = false

      engine_environment_id
        # makes sure it's called now
    end

    # Stops this expression pool (especially its workqueue).
    #
    def stop

      @stopped = true

      onotify(:stop)
    end

    # This is the first stage of the tlaunch_child() method.
    #
    # (it's used by the concurrent iterator when preparing all its
    # iteration children)
    #
    def tprepare_child (parent_exp, template, sub_id, options={})

      return fetch_expression(template) if template.is_a?(FlowExpressionId)
        # used for "scheduled launches"

      fei = parent_exp.fei.dup
      fei.expression_id = "#{fei.expid}.#{sub_id}"
      fei.expression_name = template.first

      parent_id = options[:orphan] ? nil : parent_exp.fei

      raw_exp = RawExpression.new_raw(
        fei, parent_id, nil, @application_context, template)

      if vars = options[:variables]
        raw_exp.new_environment(vars)
      else
        raw_exp.environment_id = parent_exp.environment_id
      end

      raw_exp.dup_environment if options[:dup_environment]

      #workitem.fei = raw_exp.fei
        # done in do_apply...

      if options[:register_child] == true

        (parent_exp.children ||= []) << raw_exp.fei

        update(raw_exp)

        parent_exp.store_itself unless options[:dont_store_parent]
      end

      raw_exp
    end

    # Launches the given template (sexp) as the child of its
    # parent expression.
    #
    # If the last, register_child, is set to true, this method will
    # take care of adding the new child to the parent expression.
    #
    # (used by 'cron' and more)
    #
    def tlaunch_child (parent_exp, template, sub_id, workitem, opts={})

      raw_exp = tprepare_child(parent_exp, template, sub_id, opts)

      onotify(:tlaunch_child, raw_exp.fei, workitem)

      apply(raw_exp, workitem)

      raw_exp.fei
    end

    # Launches a subprocess.
    # The resulting wfid is a subid for the wfid of the firing expression.
    #
    # (used by the 'subprocess' expression, the 'on_cancel' feature and the
    # ProcessParticipant)
    #
    def launch_subprocess (
      firing_exp, template, forget, workitem, initial_variables)

      raw_exp = build_raw_expression(template)

      raw_exp.parent_id = forget ? nil : firing_exp.fei

      raw_exp.fei.workflow_definition_url = firing_exp.fei.wfurl

      raw_exp.fei.wfid =
        "#{firing_exp.fei.parent_wfid}.#{firing_exp.get_next_sub_id}"

      raw_exp.new_environment(initial_variables)

      raw_exp.store_itself

      apply(raw_exp, workitem)

      raw_exp.fei
    end

    # Replaces the flow expression with a raw expression that has
    # the same fei, same parent and points to the same env.
    # The raw_representation will be the template.
    # Stores and then apply the "cuckoo" expression.
    #
    # Used by 'exp' and 'eval' and the do_handle_error method of the expool.
    #
    def substitute_and_apply (fexp, template, workitem)

      re = RawExpression.new_raw(
        fexp.fei,
        fexp.parent_id,
        fexp.environment_id,
        application_context,
        template)

      update(re)

      apply(re, workitem)
    end

    # Launches a new process instance.
    #
    def launch (raw_exp, workitem)

      onotify(:launch, raw_exp.fei, workitem)

      apply(raw_exp, workitem)
    end

    # Applies a given expression (id or expression)
    #
    def apply (exp_or_fei, workitem)

      get_workqueue.push(
        self, :do_apply_reply, :apply, exp_or_fei, workitem)
    end

    # Replies to a given expression
    #
    def reply (exp_or_fei, workitem)

      get_workqueue.push(
        self, :do_apply_reply, :reply, exp_or_fei, workitem)
    end

    # Cancels the given expression.
    # The param might be an expression instance or a FlowExpressionId
    # instance.
    #
    def cancel (exp)

      exp, fei = fetch(exp)

      unless exp
        linfo { "cancel() cannot cancel missing  #{fei.to_debug_s}" }
        return nil
      end

      ldebug { "cancel() for  #{fei.to_debug_s}" }

      onotify(:cancel, exp)

      wi = exp.cancel

      remove(exp)
        # will remove owned environment if any

      wi
    end

    # Cancels the given expression and makes sure to resume the flow
    # if the expression or one of its children were active.
    #
    # If the cancelled branch was not active, this method will take
    # care of removing the cancelled expression from the parent
    # expression.
    #
    def cancel_expression (exp)

      exp, fei = fetch(exp)

      raise "cannot cancel 'missing' expression #{fei.to_short_s}" unless exp

      wi = cancel(exp)

      # (remember that in case of error, no wi can get returned...)

      if wi

        reply_to_parent(exp, wi, false)

      elsif exp.parent_id

        parent_exp = fetch_expression(exp.parent_id)
        parent_exp.remove_child(exp.fei) if parent_exp
      end
    end

    # Re-applies a given expression.
    #
    # Note : this expression must be present and have been applied previously.
    #
    def reapply (exp)

      exp, fei = fetch(exp)

      raise "cannot re-apply 'missing' expression #{fei.to_short_s}" \
        unless exp

      wi = exp.applied_workitem rescue nil
      wi.attributes['__reapplied__'] = true

      raise "cannot re-apply expression #{fei.to_short_s}, not applied" \
        unless exp

      apply(exp, wi)
    end

    # Given any expression of a process, cancels the complete process
    # instance.
    #
    def cancel_process (exp_or_wfid)

      wfid = extract_wfid(exp_or_wfid, false)
        # 'true' would have made sure that the parent wfid is used...

      ldebug { "cancel_process() '#{wfid}'" }

      root = fetch_root(wfid)

      raise "no process to cancel '#{wfid}'" unless root

      cancel(root)
    end
    alias :cancel_flow :cancel_process

    # Forgets the given expression (make it an orphan).
    #
    def forget (parent_exp, exp)

      exp, fei = fetch exp

      return if not exp

      parent_exp.children.delete(fei)

      exp.parent_id = nil
      exp.dup_environment
      exp.store_itself

      onotify(:forget, exp)

      ldebug { "forget() forgot #{fei}" }
    end

    # Replies to the parent of the given expression.
    #
    def reply_to_parent (exp, workitem, remove=true)

      workitem.last_expression_id = exp.fei

      onotify(:reply_to_parent, exp, workitem)

      if remove

        remove(exp)
          #
          # remove the expression itself

        exp.clean_children
          #
          # remove all the children of the expression
      end

      #
      # manage tag, have to remove it so it can get 'redone' or 'undone'
      # (preventing abuse)
      #
      # do the same for the on_error handler if any

      tagname = exp.attributes['tag']
      exp.delete_variable(tagname) if tagname
      #exp.delete_variable(tagname) if tagname and not tagname.match(/^\//)

      on_error = exp.attributes['on_error'] #if exp.attributes
      exp.delete_variable(on_error) if on_error

      #
      # has raw_expression been updated ?

      track_child_raw_representation(exp)

      #
      # flow terminated ?

      if (not exp.parent_id) and (exp.fei.expid == '0')

        ldebug { "reply_to_parent() process #{exp.fei.wfid} terminated" }

        onotify(:terminate, exp, workitem)

        return
      end

      #
      # else, gone parent ?

      #if (not exp.parent_id) or (exp.parent_id.expname == 'gone')
      #  # this 'gone' is kept for some level of 'backward compatibility'

      if (not exp.parent_id)

        ldebug { "reply_to_parent() parent is gone for #{exp.fei.to_debug_s}"}
        return
      end

      #
      # parent still present, reply to it

      reply(exp.parent_id, workitem)
    end

    # Adds or updates a flow expression in this pool
    #
    def update (flow_expression)

      flow_expression.updated_at = Time.now

      #ldebug { "update() for #{flow_expression.fei.to_debug_s}" }

      onotify(:update, flow_expression.fei, flow_expression)

      flow_expression
    end

    # Fetches a FlowExpression from the pool.
    # Returns a tuple : the FlowExpression plus its FlowExpressionId.
    #
    # The param 'exp' may be a FlowExpressionId or a FlowExpression that
    # has to be reloaded.
    #
    def fetch (exp)

      fei = extract_fei(exp)

      [ get_expression_storage[fei], fei ]
    end

    # Fetches a FlowExpression (returns only the FlowExpression instance)
    #
    # The param 'exp' may be a FlowExpressionId or a FlowExpression that
    # has to be reloaded.
    #
    def fetch_expression (exp)

      fetch(exp)[0]
    end

    # Returns the engine environment (the top level environment)
    #
    def fetch_engine_environment

      eei = engine_environment_id
      ee, fei = fetch(eei)

      return ee if ee

      ee = Environment.new_env(eei, nil, nil, @application_context, nil)
      ee.store_itself
      ee
    end

    # Fetches the root expression of a process (or a subprocess).
    #
    def fetch_root (wfid)

      get_expression_storage.fetch_root(wfid)
    end

    # Removes a flow expression from the pool
    # (This method is mainly called from the pool itself)
    #
    def remove (exp)

      exp, _fei = fetch(exp) if exp.is_a?(FlowExpressionId)

      return unless exp

      #ldebug { "remove() fe  #{exp.fei.to_debug_s}" }

      onotify(:remove, exp.fei)

      remove_environment(exp.environment_id) if exp.owns_its_environment?
    end

    # This method is called at each expool (engine) [re]start.
    # It roams through the previously saved (persisted) expressions
    # to reschedule ones like 'sleep' or 'cron'.
    #
    def reschedule

      return if @stopped

      t = OpenWFE::Timer.new

      linfo { 'reschedule() initiating...' }

      options = { :include_classes => Rufus::Schedulable }

      get_expression_storage.find_expressions(options).each do |fexp|

        linfo { "reschedule() for  #{fexp.fei.to_s}..." }

        onotify(:reschedule, fexp.fei)

        fexp.reschedule(get_scheduler)
      end

      linfo { "reschedule() done. (took #{t.duration} ms)" }
    end

    # Returns the unique engine_environment FlowExpressionId instance.
    # There is only one such environment in an engine, hence this
    # 'singleton' method.
    #
    def engine_environment_id

      @eei ||= new_fei(
        :workflow_definition_url => 'ee',
        :workflow_definition_name => 'ee',
        :workflow_instance_id => '0',
        :expression_name => EN_ENVIRONMENT)
    end

    # This method is called when apply() or reply() failed for
    # an expression.
    # There are currently only two 'users', the ParticipantExpression
    # class and the do_process_workelement method of this ExpressionPool
    # class.
    #
    # Error handling is done here, if no handler was found, the error simply
    # generate a notification (generally caught by an error journal).
    #
    def handle_error (error, fei, message, workitem)

      fei = extract_fei(fei) # just to be sure

      if error.is_a?(PausedError)
        lwarn do
          "#{self.service_name} " +
          "operation :#{message.to_s} on #{fei.to_s} " +
          "delayed because process '#{fei.wfid}' is in pause"
        end
      else
        lwarn do
          "#{self.service_name} " +
          "operation :#{message.to_s} on #{fei.to_s} " +
          "failed with\n" + OpenWFE::exception_to_s(error)
        end
      end

      # notify or really handle ?

      do_handle_error(fei, workitem) ||
      onotify(:error, fei, message, workitem, error.class.name, error.to_s)
    end

    # Returns true if the process instance to which the expression
    # belongs is currently paused.
    #
    def is_paused? (expression)

      (@paused_instances[expression.fei.parent_wfid] != nil)
    end

    # Builds the RawExpression instance at the root of the flow
    # being launched.
    #
    # The param can be a template or a definition (or a URI).
    #
    def build_raw_expression (param, launchitem=nil)

      procdef = get_def_parser.determine_rep(param)

      # procdef is a nested [ name, attributes, children ] structure now

      atts = procdef[1]

      h = {
        :workflow_instance_id =>
          get_wfid_generator.generate(launchitem),
        :workflow_definition_name =>
          atts['name'] || procdef[2].first || 'no-name',
        :workflow_definition_revision =>
          atts['revision'] || '0',
        :expression_name =>
          procdef[0]
      }

      h[:workflow_definition_url] = (
        launchitem.workflow_definition_url || LaunchItem::FIELD_DEF
      ) if launchitem

      RawExpression.new_raw(
        new_fei(h), nil, nil, @application_context, procdef)
    end

    # If the launch option :wait_for is set to true, this method
    # will be called to apply the raw_expression. It will only return
    # when the launched process is over, which means it terminated, it
    # had an error or it got cancelled.
    #
    def wait_for (fei_or_wfid)

      wfid = extract_wfid(fei_or_wfid, false)

      t = Thread.current
      result = nil

      to = add_observer(:terminate) do |c, fe, wi|
        if fe.fei.wfid == wfid
          result = [ :terminate, wi, fei_or_wfid ]
          t.wakeup
        end
      end
      te = add_observer(:error) do |c, fei, m, i, e|
        if fei.parent_wfid == wfid
          result = [ :error, e, fei_or_wfid ]
          t.wakeup
        end
      end
      tc = add_observer(:cancel) do |c, fe|
        if fe.fei.wfid == wfid and fe.fei.expid == '0'
          result = [ :cancel, wfid, fei_or_wfid ]
          t.wakeup
        end
      end

      yield if block_given?

      Thread.stop unless result

      linfo { "wait_for() '#{wfid}' is over" }

      remove_observer(to, :terminate)
      remove_observer(te, :error)
      remove_observer(tc, :cancel)

      result
    end

    protected

    # Checks if there is an event handler available
    #
    def do_handle_error (fei, workitem)

      fexp = fetch_expression(fei)

      eh_stack = fexp.lookup_variable_stack('error_handlers')

      return false if eh_stack.empty?

      eh_stack.each do |env, ehandlers|
        ehandlers.reverse.each do |ehandler|

          fei, on_error = ehandler

          next unless fexp.descendant_of?(fei)

          return false if on_error == ''
            #
            # blanking the 'on_error' makes the block behave like if there
            # were no error handler at all (error is then passed to error
            # journal usually (if there is one listening))

          tryexp = fetch_expression(fei)

          # remove error handler before consuming it

          ehandlers.delete(ehandler)
          env.store_itself

          # fetch on_error template

          template = (on_error == 'redo') ?
            tryexp.raw_representation :
            tryexp.lookup_variable(on_error) || [ on_error, {}, [] ]

          # cancel block that is adorned with 'on_error'

          environment = tryexp.owns_its_environment? ?
            tryexp.get_environment : nil

          cancel(tryexp)

          ldebug { "do_handle_error() on_error : '#{on_error}'" }

          if on_error == 'undo'
            #
            # block with 'undo' error handler simply gets undone in case of
            # error
            #
            reply_to_parent(tryexp, workitem, false)
            return true
          end

          # switch to error handling subprocess

          environment.store_itself if environment
            #
            # the point of error had variables, make sure they are available
            # to the error handling block.

          substitute_and_apply(tryexp, template, workitem)

          return true
        end
      end

      false # no error handler found
    end

    # This is the method called [asynchronously] by the WorkQueue
    # upon apply/reply.
    #
    def do_apply_reply (direction, exp_or_fei, workitem)

      fei = nil

      begin

        exp, fei = if exp_or_fei.is_a?(FlowExpressionId)
          fetch(exp_or_fei)
        else
          [ exp_or_fei, exp_or_fei.fei ]
        end

        #p [ direction, fei.wfid, fei.expid, fei.expname ]
          #
          # I uncomment that sometimes to see how the stack
          # grows (wfids and expids)

        if not exp

          #raise "apply() cannot apply missing #{_fei.to_debug_s}"
            # not very helpful anyway

          lwarn { "do_apply_reply() :#{direction} but cannot find #{fei}" }

          return
        end

        check_if_paused(exp)

        workitem.fei = exp.fei if direction == :apply

        onotify(direction, exp, workitem)

        exp.send(direction, workitem)

      rescue Exception => e

        handle_error(e, fei, direction, workitem)
      end
    end

    # Will raise an exception if the expression belongs to a paused
    # process.
    #
    def check_if_paused (expression)

      wfid = expression.fei.parent_wfid

      raise PausedError.new(wfid) if @paused_instances[wfid]
    end

    # Removes an environment, especially takes care of unbinding
    # any special value it may contain.
    #
    def remove_environment (environment_id)

      #ldebug { "remove_environment()  #{environment_id.to_debug_s}" }

      env, fei = fetch(environment_id)

      return unless env
        #
        # env already unbound and removed

      env.unbind

      onotify(:remove, environment_id)
    end

    # Builds a FlowExpressionId instance for a process being
    # launched.
    #
    def new_fei (h)

      h[:engine_id] = OpenWFE::stu(get_engine.engine_name)

      %w{ url name revision }.each { |k| stu(h, k) }

      FlowExpressionId.new_fei(h)
    end

    def stu (h, key)

      key = "workflow_definition_#{key}".intern
      v = h[key]
      h[key] = OpenWFE::stu(v.to_s) if v
    end

    # Given a [replying] child flow expression, will update its parent
    # raw expression if the child raw_expression changed.
    #
    # This is used to keep track of in-flight modification to running
    # process instances.
    #
    def track_child_raw_representation (fexp)

      return unless fexp.raw_rep_updated == true

      parent = fetch_expression(fexp.parent_id)

      #p [ :storing, fexp.raw_representation, fexp.fei.to_short_s ]

      parent.raw_children[fexp.fei.child_id.to_i] = fexp.raw_representation

      parent.store_itself
    end
  end

end

