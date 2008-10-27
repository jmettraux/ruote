#
#--
# Copyright (c) 2006-2008, John Mettraux, OpenWFE.org
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

require 'uri'

require 'openwfe/utils'
require 'openwfe/service'
require 'openwfe/logging'
require 'openwfe/omixins'
require 'openwfe/rudefinitions'
require 'openwfe/flowexpressionid'
require 'openwfe/util/observable'
require 'openwfe/expool/parser'
require 'openwfe/expool/representation'
require 'openwfe/expool/paused_error'
require 'openwfe/expool/expool_pause_methods'
require 'openwfe/expressions/environment'
require 'openwfe/expressions/raw'

require 'rufus/verbs' # gem 'rufus-lru'


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

    #
    # The hash containing the wfid of the process instances currently
    # paused (a cache).
    #
    attr_reader :paused_instances

    #
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

    #
    # Stops this expression pool (especially its workqueue).
    #
    def stop

      @stopped = true

      onotify :stop
    end

    #
    # This method is called by the launch method. It's actually the first
    # stage of that method.
    # It may be interessant to use to 'validate' a launchitem and its
    # process definition, as it will raise an exception in case
    # of 'parameter' mismatch.
    #
    # There is a 'pre_launch_check' alias for this method in the
    # Engine class.
    #
    def prepare_raw_expression (launchitem)

      wfdurl = launchitem.workflow_definition_url

      definition, in_launchitem = if (not wfdurl)

        [ launchitem.attributes.delete('__definition'), true ]

      elsif wfdurl[0, 6] == 'field:'

        [ launchitem.attributes.delete(wfdurl[6..-1]), true ]

      else

        [ read_uri(wfdurl), false ]
      end

      raise(
        "didn't find process definition at '#{wfdurl}'"
      ) unless definition

      raise(
        ":definition_in_launchitem_allowed not set to true, cannot launch."
      ) if in_launchitem and ac[:definition_in_launchitem_allowed] != true

      raw_expression = build_raw_expression(definition, launchitem)

      raw_expression.check_parameters(launchitem)
        #
        # will raise an exception if there are requirements
        # and one of them is not met

      raw_expression.store_itself

      raw_expression
    end

    #
    # Instantiates a workflow definition and launches it.
    #
    # This method call will return immediately, it could even return
    # before the actual launch is completely over.
    #
    # Returns the FlowExpressionId instance of the root expression of
    # the newly launched flow.
    #
    def launch (launchitem, options={})

      wait = (options.delete(:wait_for) == true)
      initial_variables = options.delete(:vars) || options.delete(:variables)

      #
      # prepare raw expression

      raw_expression = prepare_raw_expression(launchitem)
        #
        # will raise an exception if there are requirements
        # and one of them is not met

      raw_expression.new_environment(initial_variables)
        #
        # as this expression is the root of a new process instance,
        # it has to have an environment for all the variables of
        # the process instance
        #
        # (new_environment() calls store_itself on the new env)

      raw_expression = wrap_in_schedule(raw_expression, options) \
        if (options.keys & [ :in, :at, :cron, :every ]).size > 0

      fei = raw_expression.fei

      #
      # apply prepared raw expression

      onotify(:launch, fei, launchitem)

      wi = build_workitem(launchitem)

      if wait
        wait_for(fei) { apply(raw_expression, wi) }
      else
        apply(raw_expression, wi)
        fei
      end
    end

    #
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

    #
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

    #
    # Launches a subprocess.
    # The resulting wfid is a subid for the wfid of the firing expression.
    #
    # (used by 'subprocess')
    #
    def launch_subprocess (
      firing_exp, template, forget, workitem, params)

      raw_exp = build_raw_expression(template)

      raw_exp.parent_id = forget ? nil : firing_exp.fei

      raw_exp.fei.workflow_definition_url = firing_exp.fei.wfurl

      raw_exp.fei.wfid =
        "#{firing_exp.fei.parent_wfid}.#{firing_exp.get_next_sub_id}"

      raw_exp.new_environment(params)

      raw_exp.store_itself

      apply(raw_exp, workitem)

      raw_exp.fei
    end

    #
    # Replaces the flow expression with a raw expression that has
    # the same fei, same parent and points to the same env.
    # The raw_representation will be the template.
    # Stores and then apply the "cuckoo" expression.
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

    #
    # Applies a given expression (id or expression)
    #
    def apply (exp_or_fei, workitem)

      get_workqueue.push(
        self, :do_apply_reply, :apply, exp_or_fei, workitem)
    end

    #
    # Replies to a given expression
    #
    def reply (exp_or_fei, workitem)

      get_workqueue.push(
        self, :do_apply_reply, :reply, exp_or_fei, workitem)
    end

    #
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

      wi
    end

    #
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

      # ( remember that in case of error, no wi could get returned...)

      if wi

        reply_to_parent(exp, wi, false)

      elsif exp.parent_id

        parent_exp = fetch_expression(exp.parent_id)
        parent_exp.remove_child(exp.fei) if parent_exp
      end
    end

    #
    # Given any expression of a process, cancels the complete process
    # instance.
    #
    def cancel_process (exp_or_wfid)

      wfid = extract_wfid(exp_or_wfid, false)
        # 'true' would have made sure that the parent wfid is used...

      ldebug { "cancel_process() '#{wfid}'" }

      root = fetch_root wfid

      raise "no process to cancel '#{wfid}'" unless root

      cancel root
    end
    alias :cancel_flow :cancel_process

    #
    # Forgets the given expression (make it an orphan).
    #
    def forget (parent_exp, exp)

      exp, fei = fetch exp

      #ldebug { "forget() forgetting  #{fei}" }

      return if not exp

      parent_exp.children.delete(fei)

      exp.parent_id = nil
      exp.dup_environment
      exp.store_itself

      onotify(:forget, exp)

      ldebug { "forget() forgot #{fei}" }
    end

    #
    # Replies to the parent of the given expression.
    #
    def reply_to_parent (exp, workitem, remove=true)

      #puts
      #p "reply_to_parent() for #{exp.fei.to_debug_s}"
      #puts caller.join("\n")
      #puts
      #ldebug { "reply_to_parent() for #{exp.fei.to_debug_s}" }

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

      tagname = exp.attributes['tag'] if exp.attributes

      exp.delete_variable(tagname) if tagname

      #
      # has raw_expression been updated ?

      track_child_raw_representation(exp)

      #
      # flow terminated ?

      if (not exp.parent_id) and (exp.fei.expid == '0')

        ldebug do
          "reply_to_parent() process " +
          "#{exp.fei.workflow_instance_id} terminated"
        end

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

    #
    # Adds or updates a flow expression in this pool
    #
    def update (flow_expression)

      flow_expression.updated_at = Time.now

      ldebug { "update() for #{flow_expression.fei.to_debug_s}" }

      #t = Timer.new

      onotify :update, flow_expression.fei, flow_expression

      #ldebug do
      #  "update() took #{t.duration} ms  " +
      #  "#{flow_expression.fei.to_debug_s}"
      #end

      flow_expression
    end

    #
    # Fetches a FlowExpression from the pool.
    # Returns a tuple : the FlowExpression plus its FlowExpressionId.
    #
    # The param 'exp' may be a FlowExpressionId or a FlowExpression that
    # has to be reloaded.
    #
    def fetch (exp)

      fei = if exp.is_a?(FlowExpression)

        exp.fei

      elsif not exp.is_a?(FlowExpressionId)

        raise "Cannot fetch expression with key : '#{fei}' (#{fei.class})"

      else

        exp
      end

      [ get_expression_storage[fei], fei ]
    end

    #
    # Fetches a FlowExpression (returns only the FlowExpression instance)
    #
    # The param 'exp' may be a FlowExpressionId or a FlowExpression that
    # has to be reloaded.
    #
    def fetch_expression (exp)

      exp, fei = fetch(exp)
      exp
    end

    #
    # Returns the engine environment (the top level environment)
    #
    def fetch_engine_environment

      eei = engine_environment_id
      ee, fei = fetch(eei)

      return ee if ee

      ee = Environment.new_env(
        eei, nil, nil, @application_context, nil)

      ee.store_itself

      ee
    end

    #
    # Fetches the root expression of a process (or a subprocess).
    #
    def fetch_root (wfid)

      get_expression_storage.fetch_root wfid
    end

    #
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

    #
    # This method is called at each expool (engine) [re]start.
    # It roams through the previously saved (persisted) expressions
    # to reschedule ones like 'sleep' or 'cron'.
    #
    def reschedule

      return if @stopped

      t = OpenWFE::Timer.new

      linfo { "reschedule() initiating..." }

      options = { :include_classes => Rufus::Schedulable }

      get_expression_storage.find_expressions(options).each do |fexp|

        linfo { "reschedule() for  #{fexp.fei.to_s}..." }

        onotify :reschedule, fexp.fei

        fexp.reschedule get_scheduler
      end

      linfo { "reschedule() done. (took #{t.duration} ms)" }
    end

    #
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

    #
    # Returns the list of applied expressions belonging to a given
    # workflow instance.
    #
    # If the unapplied optional parameter is set to true, all the
    # expressions (even those not yet applied) that compose the process
    # instance will be returned. Environments will be returned as well.
    #
    #def process_stack (wfid, unapplied=false)
    def process_stack (wfid)

      #raise "please provide a non-nil workflow instance id" \
      #  unless wfid

      wfid = extract_wfid wfid, true

      params = {
        #:exclude_classes => [ Environment, RawExpression ],
        #:exclude_classes => [ Environment ],
        :parent_wfid => wfid
      }
      #params[:applied] = true if (not unapplied)

      stack = get_expression_storage.find_expressions params

      #stack.extend(RepresentationMixin) if unapplied
      stack.extend(RepresentationMixin)

      stack
    end

    #
    # Lists all workflows (processes) currently in the expool (in
    # the engine).
    # This method will return a list of "process-definition" expressions
    # (root of flows).
    #
    def list_processes (options={})

      options[:include_classes] = DefineExpression
        #
        # Maybe it would be better to list root expressions instead
        # so that expressions like 'sequence' can be used
        # as root expressions. Later...

      get_expression_storage.find_expressions(options)
    end

    #
    # This method is called when apply() or reply() failed for
    # an expression.
    # There are currently only two 'users', the ParticipantExpression
    # class and the do_process_workelement method of this ExpressionPool
    # class.
    #
    def notify_error (error, fei, message, workitem)

      fei = extract_fei fei
        # densha requires that... :(

      se = OpenWFE::exception_to_s error

      #onotify :error, fei, message, workitem, error.class.name, se
      onotify(:error, fei, message, workitem, error.class.name, error.to_s)

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
          "failed with\n" + se
        end
      end
    end

    #
    # Gets the process definition (if necessary) and turns into
    # into an expression tree (for storing into a RawExpression).
    #
    def determine_rep (param)

      param = read_uri(param) if param.is_a?(URI)

      get_def_parser.parse(param)
    end

    #
    # Returns true if the process instance to which the expression
    # belongs is currently paused.
    #
    def is_paused? (expression)

      (@paused_instances[expression.fei.parent_wfid] != nil)
    end

    protected

      #
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
          if fe.fei.workflow_instance_id == wfid
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

      #
      # This is the only point in the expression pool where an URI
      # is read, so this is where the :remote_definitions_allowed
      # security check is enforced.
      #
      def read_uri (uri)

        uri = URI.parse uri.to_s

        raise ":remote_definitions_allowed is set to false" \
          if (ac[:remote_definitions_allowed] != true and
            uri.scheme and
            uri.scheme != 'file')

        #open(uri.to_s).read

        f = Rufus::Verbs.fopen uri
        result = f.read
        f.close if f.respond_to?(:close)

        result
      end

      #
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

          notify_error(e, fei, direction, workitem)
        end
      end

      #
      # Will raise an exception if the expression belongs to a paused
      # process.
      #
      def check_if_paused (expression)

        wfid = expression.fei.parent_wfid

        raise PausedError.new(wfid) if @paused_instances[wfid]
      end

      #
      # if the launch method is called with a schedule option
      # (like :at, :in, :cron and :every), this method takes care of
      # wrapping the process with a sleep or a cron.
      #
      def wrap_in_schedule (raw_expression, options)

        oat = options[:at]
        oin = options[:in]
        ocron = options[:cron]
        oevery = options[:every]

        fei = new_fei(
          :workflow_instance_id => get_wfid_generator.generate(nil),
          :workflow_definition_name => 'schedlaunch',
          :expression_name => 'sequence')

        # not very happy with this code, it builds custom
        # wrapping processes manually, maybe there is
        # a more elegant way, but for now, it's ok.

        template = if oat or oin

          sleep_atts = if oat
            { 'until' => oat }
          else #oin
            { 'for' => oin }
          end
          sleep_atts['scheduler-tags'] = "scheduled-launch, #{fei.wfid}"

          raw_expression.new_environment
          raw_expression.store_itself

          [
            'sequence', {}, [
              [ 'sleep', sleep_atts, [] ],
              raw_expression.fei
            ]
          ]

        elsif ocron or oevery

          fei.expression_name = 'cron'

          cron_atts = if ocron
            { 'tab' => ocron }
          else #oevery
            { 'every' => oevery }
          end
          cron_atts['name'] = "//cron_launch__#{fei.wfid}"
          cron_atts['scheduler-tags'] = "scheduled-launch, #{fei.wfid}"

          template = raw_expression.raw_representation
          remove(raw_expression)

          [ 'cron', cron_atts, [ template ] ]

        else

          nil # don't schedule at all
        end

        if template

          raw_exp = RawExpression.new_raw(
            fei, nil, nil, @application_context, template)

          #raw_exp.store_itself
          raw_exp.new_environment

          raw_exp
        else

          raw_expression
        end
      end

      #
      # Removes an environment, especially takes care of unbinding
      # any special value it may contain.
      #
      def remove_environment (environment_id)

        ldebug { "remove_environment()  #{environment_id.to_debug_s}" }

        env, fei = fetch(environment_id)

        return unless env
          #
          # env already unbound and removed

        env.unbind

        onotify(:remove, environment_id)
      end

      #
      # Prepares a new instance of InFlowWorkItem from a LaunchItem
      # instance.
      #
      def build_workitem (launchitem)

        wi = InFlowWorkItem.new

        wi.attributes = launchitem.attributes.dup

        wi
      end

      #
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

      #
      # Builds the RawExpression instance at the root of the flow
      # being launched.
      #
      # The param can be a template or a definition (anything
      # accepted by the determine_representation() method).
      #
      def build_raw_expression (param, launchitem=nil)

        procdef = determine_rep(param)
        atts = procdef[1]

        h = {
          :workflow_instance_id =>
            get_wfid_generator.generate(launchitem),
          :workflow_definition_name =>
            atts['name'] || procdef[2].first || 'no-name',
          :workflow_definition_revision =>
            atts['revision'] || '0',
          :expression_name =>
            procdef[0] }

        h[:workflow_definition_url] = (
          launchitem.workflow_definition_url || LaunchItem::FIELD_DEF
        ) if launchitem

        RawExpression.new_raw(
          new_fei(h), nil, nil, @application_context, procdef)
      end

      #
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

