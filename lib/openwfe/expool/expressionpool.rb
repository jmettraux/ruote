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
require 'openwfe/expressions/environment'
require 'openwfe/expressions/raw'

require 'rufus/lru' # gem 'rufus-lru'
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

        #
        # The hash containing the wfid of the process instances currently
        # paused.
        #
        attr_reader :paused_instances

        #
        # The constructor for the expression pool.
        #
        def initialize (service_name, application_context)

            super()
            
            service_init service_name, application_context

            @paused_instances = {}

            #@monitors = MonitorProvider.new(application_context)

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

        #--
        # Obtains a unique monitor for an expression.
        # It avoids the need for the FlowExpression instances to include
        # the monitor mixin by themselves
        #
        #def get_monitor (fei)
        #    @monitors[fei]
        #end
        #++

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

            raise "launchitem.workflow_definition_url not set, cannot launch" \
                unless wfdurl

            definition = if wfdurl.match "^field:"

                wfdfield = wfdurl[6..-1]
                launchitem.attributes.delete wfdfield
            else

                read_uri wfdurl
            end

            raise "didn't find process definition at '#{wfdurl}'" \
                unless definition

            raw_expression = build_raw_expression launchitem, definition

            raw_expression.check_parameters launchitem
                #
                # will raise an exception if there are requirements
                # and one of them is not met

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

            #
            # prepare raw expression

            raw_expression = prepare_raw_expression launchitem
                #
                # will raise an exception if there are requirements
                # and one of them is not met

            raw_expression = wrap_in_schedule(raw_expression, options) \
                if options.size > 0

            raw_expression.new_environment
                #
                # as this expression is the root of a new process instance,
                # it has to have an environment for all the variables of 
                # the process instance

            fei = raw_expression.fei

            #
            # apply prepared raw expression

            wi = build_workitem launchitem

            onotify :launch, fei, launchitem

            apply raw_expression, wi

            fei
        end

        #
        # This is the first stage of the tlaunch_child() method.
        #
        # (it's used by the concurrent iterator when preparing all its 
        # iteration children)
        #
        def tprepare_child (
            parent_exp, template, sub_id, register_child, vars)

            return fetch_expression(template) \
                if template.is_a?(FlowExpressionId)

            fei = parent_exp.fei.dup
            fei.expression_name = template.first
            fei.expression_id = "#{fei.expid}.#{sub_id}"

            raw_exp = RawExpression.new_raw(
                fei, nil, nil, @application_context, template)

            raw_exp.parent_id = parent_exp.fei

            if vars
                raw_exp.new_environment vars
            else
                raw_exp.environment_id = parent_exp.environment_id
            end

            #workitem.fei = raw_exp.fei
                # done in do_apply...

            if register_child
                (parent_exp.children ||= []) << raw_exp.fei
                update raw_exp
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
        def tlaunch_child (
            parent_exp, template, sub_id, workitem, register_child, vars=nil)

            raw_exp = tprepare_child(
                parent_exp, template, sub_id, register_child, vars)

            onotify :tlaunch_child, raw_exp.fei, workitem

            apply raw_exp, workitem

            raw_exp.fei
        end

        #
        # Launches a template, but makes sure the new expression has no
        # parent.
        #
        # (used by 'listen')
        #
        def tlaunch_orphan (
            firing_exp, template, sub_id, workitem, register_child)

            fei = firing_exp.fei.dup
            fei.expression_id = "#{fei.expid}.#{sub_id}"
            fei.expression_name = template.first

            raw_exp = RawExpression.new_raw(
                fei, nil, nil, @application_context, template)

            #raw_exp.parent_id = GONE_PARENT_ID
            raw_exp.parent_id = nil
                # it's an orphan, no parent

            raw_exp.environment_id = firing_exp.environment_id
                # tapping anyway into the firer's environment

            (firing_exp.children ||= []) << raw_exp.fei \
                if register_child

            onotify :tlaunch_orphan, raw_exp.fei, workitem

            apply raw_exp, workitem

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

            raw_exp = if template.is_a?(FlowExpressionId)

                fetch_expression template

            elsif template.is_a?(RawExpression)

                template.application_context = @application_context
                template

            else # probably an URI

                build_raw_expression nil, template
            end

            raw_exp = raw_exp.dup
            raw_exp.fei = raw_exp.fei.dup

            if forget
                raw_exp.parent_id = nil
            else
                raw_exp.parent_id = firing_exp.fei
            end

            #raw_exp.fei.wfid = get_wfid_generator.generate
            raw_exp.fei.wfid = 
                "#{firing_exp.fei.wfid}.#{firing_exp.get_next_sub_id}"

            raw_exp.new_environment params

            raw_exp.store_itself

            apply raw_exp, workitem

            raw_exp.fei
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

            exp, fei = fetch exp

            unless exp
                ldebug { "cancel() cannot cancel missing  #{fei.to_debug_s}" }
                return nil
            end

            ldebug { "cancel() for  #{fei.to_debug_s}" }

            onotify :cancel, exp

            inflowitem = exp.cancel()
            remove exp

            inflowitem
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

            exp = fetch_expression exp

            wi = cancel exp

            if wi
                reply_to_parent exp, wi, false
            else
                parent_exp = fetch_expression exp.parent_id
                parent_exp.remove_child(exp.fei) if parent_exp
            end
        end

        #
        # Given any expression of a process, cancels the complete process
        # instance.
        #
        def cancel_process (exp_or_wfid)

            wfid = extract_wfid exp_or_wfid, false

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

            onotify :forget, exp

            parent_exp.children.delete(fei)

            #exp.parent_id = GONE_PARENT_ID
            exp.parent_id = nil

            exp.dup_environment
            exp.store_itself()

            ldebug { "forget() forgot      #{fei}" }
        end

        #
        # Replies to the parent of the given expression.
        #
        def reply_to_parent (exp, workitem, remove=true)

            ldebug { "reply_to_parent() for #{exp.fei.to_debug_s}" }

            workitem.last_expression_id = exp.fei

            onotify :reply_to_parent, exp, workitem

            if remove

                remove exp
                    #
                    # remove the expression itself

                exp.clean_children
                    #
                    # remove all the children of the expression
            end

            #
            # manage tag, have to remove it so it can get 'redone' or 'undone'
            # (preventing abuse)

            tagname = exp.attributes["tag"] if exp.attributes

            exp.delete_variable(tagname) if tagname

            #
            # has raw_expression been updated ?

            track_child_raw_representation exp

            #
            # flow terminated ?

            #if not exp.parent_id
            if (not exp.parent_id) and (exp.fei.expid == '0')

                ldebug do 
                    "reply_to_parent() process " +
                    "#{exp.fei.workflow_instance_id} terminated"
                end

                onotify :terminate, exp, workitem

                return
            end

            #
            # else, gone parent ?

            #if exp.parent_id == GONE_PARENT_ID
            if (not exp.parent_id) or (exp.parent_id.expname == 'gone')
                # this 'gone' is kept for some level of 'backward compatibility'

                ldebug do
                    "reply_to_parent() parent is gone for  " +
                    exp.fei.to_debug_s
                end

                return
            end

            #
            # parent still present, reply to it

            reply exp.parent_id, workitem
        end

        #
        # Adds or updates a flow expression in this pool
        #
        def update (flow_expression)

            ldebug { "update() for #{flow_expression.fei.to_debug_s}" }

            #t = Timer.new

            onotify :update, flow_expression.fei, flow_expression

            #ldebug do 
            #    "update() took #{t.duration} ms  " +
            #    "#{flow_expression.fei.to_debug_s}"
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
            #synchronize do

            #ldebug { "fetch() exp is of kind #{exp.class}" }

            fei = if exp.is_a?(FlowExpression)

                exp.fei 

            elsif not exp.is_a?(FlowExpressionId)

                raise \
                    "Cannot fetch expression with key : "+
                    "'#{fei}' (#{fei.class})"

            else

                exp
            end

            #ldebug { "fetch() for  #{fei.to_debug_s}" }

            [ get_expression_storage[fei], fei ]
            #end
        end

        #
        # Fetches a FlowExpression (returns only the FlowExpression instance)
        #
        # The param 'exp' may be a FlowExpressionId or a FlowExpression that
        # has to be reloaded.
        #
        def fetch_expression (exp)

            exp, fei = fetch exp
            exp
        end

        #
        # Returns the engine environment (the top level environment)
        #
        def fetch_engine_environment
            #synchronize do
                #
                # synchronize to ensure that there's 1! engine env

            eei = engine_environment_id
            ee, fei = fetch eei

            return ee if ee

            ee = Environment.new_env(
                eei, nil, nil, @application_context, nil)

            ee.store_itself

            ee
            #end
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

            exp, _fei = fetch(exp) \
                if exp.is_a?(FlowExpressionId)

            return unless exp

            ldebug { "remove() fe  #{exp.fei.to_debug_s}" }

            onotify :remove, exp.fei

            #synchronize do
            #@monitors.delete(exp.fei)

            remove_environment(exp.environment_id) \
                if exp.owns_its_environment?
            #end
        end

        #
        # This method is called at each expool (engine) [re]start.
        # It roams through the previously saved (persisted) expressions
        # to reschedule ones like 'sleep' or 'cron'.
        #
        def reschedule

            return if @stopped

            #synchronize do

            t = OpenWFE::Timer.new

            linfo { "reschedule() initiating..." }

            options = { :include_classes => Rufus::Schedulable }

            get_expression_storage.find_expressions(options).each do |fexp|

                linfo { "reschedule() for  #{fexp.fei.to_s}..." }

                onotify :reschedule, fexp.fei

                fexp.reschedule get_scheduler
            end

            linfo { "reschedule() done. (took #{t.duration} ms)" }
            #end
        end

        #
        # Returns the unique engine_environment FlowExpressionId instance.
        # There is only one such environment in an engine, hence this 
        # 'singleton' method.
        #
        def engine_environment_id
            #synchronize do 
                # no need, it's been already called at initialization

            return @eei if @eei

            @eei = FlowExpressionId.new
            @eei.owfe_version = OPENWFERU_VERSION
            @eei.engine_id = get_engine.service_name
            @eei.initial_engine_id = @eei.engine_id
            @eei.workflow_definition_url = 'ee'
            @eei.workflow_definition_name = 'ee'
            @eei.workflow_definition_revision = '0'
            @eei.workflow_instance_id = '0'
            @eei.expression_name = EN_ENVIRONMENT
            @eei.expression_id = '0'
            @eei
            #end
        end

        #
        # Returns the list of applied expressions belonging to a given
        # workflow instance.
        #
        # If the unapplied optional parameter is set to true, all the
        # expressions (even those not yet applied) that compose the process
        # instance will be returned. Environments will be returned as well.
        #
        def process_stack (wfid, unapplied=false)

            #raise "please provide a non-nil workflow instance id" \
            #    unless wfid

            wfid = extract_wfid wfid, true

            params = {
                #:exclude_classes => [ Environment, RawExpression ],
                #:exclude_classes => [ Environment ],
                :parent_wfid => wfid
            }
            params[:applied] = true if (not unapplied)

            stack = get_expression_storage.find_expressions params

            stack.extend(RepresentationMixin) if unapplied

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

            get_expression_storage.find_expressions options
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

            onotify :error, fei, message, workitem, error.class.name, se

            #fei = extract_fei fei

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

            DefParser.parse param
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
                        fetch exp_or_fei
                    else
                        [ exp_or_fei, exp_or_fei.fei ]
                    end

                    ldebug {
                        ":#{direction} "+
                        "target #{fei.to_debug_s}" }

                    if not exp

                        #raise "apply() cannot apply missing #{_fei.to_debug_s}"
                            # not very helpful anyway

                        lwarn { "do_apply_reply() cannot find >#{fei}" }

                        return
                    end

                    check_if_paused exp

                    workitem.fei = exp.fei if direction == :apply

                    onotify direction, exp, workitem

                    exp.send direction, workitem

                rescue Exception => e

                    notify_error e, fei, direction, workitem
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

                fei = new_fei nil, "schedlaunch", "0", "sequence"

                # not very happy with this code, it builds custom
                # wrapping processes manually, maybe there is 
                # a more elegant way, but for now, it's ok.

                template = if oat or oin

                    sleep_atts = if oat
                        { "until" => oat }
                    else #oin
                        { "for" => oin }
                    end
                    sleep_atts["scheduler-tags"] = "scheduled-launch"

                    raw_expression.new_environment
                    raw_expression.store_itself

                    [ 
                        "sequence", {}, [
                            [ "sleep", sleep_atts, [] ],
                            raw_expression.fei
                        ]
                    ]

                elsif ocron or oevery

                    fei.expression_name = "cron"

                    cron_atts = if ocron
                        { "tab" => ocron }
                    else #oevery
                        { "every" => oevery }
                    end
                    cron_atts["name"] = "//cron_launch__#{fei.wfid}"
                    cron_atts["scheduler-tags"] = "scheduled-launch"

                    template = raw_expression.raw_representation
                    remove raw_expression

                    [ "cron", cron_atts, [ template ] ]

                else

                    nil # don't schedule at all
                end

                if template

                    raw_exp = RawExpression.new_raw(
                        fei, nil, nil, @application_context, template)
                    
                    raw_exp.store_itself

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

                #get_expression_storage().delete(environment_id)

                onotify :remove, environment_id
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
            def new_fei (launchitem, flow_name, flow_revision, exp_name)

                url = if launchitem
                    launchitem.workflow_definition_url
                else
                    "no-url"
                end

                fei = FlowExpressionId.new

                fei.owfe_version = OPENWFERU_VERSION
                fei.engine_id = OpenWFE::stu get_engine.service_name
                fei.initial_engine_id = OpenWFE::stu fei.engine_id
                fei.workflow_definition_url = OpenWFE::stu url
                fei.workflow_definition_name = OpenWFE::stu flow_name
                fei.workflow_definition_revision = OpenWFE::stu flow_revision
                fei.wfid = get_wfid_generator.generate launchitem
                fei.expression_id = "0"
                fei.expression_name = exp_name

                fei
            end

            #
            # Builds the RawExpression instance at the root of the flow
            # being launched.
            #
            # The param can be a template or a definition (anything
            # accepted by the determine_representation() method).
            #
            def build_raw_expression (launchitem, param)

                procdef = determine_rep param

                atts = procdef[1]
                flow_name = atts['name'] || "noname"
                flow_revision = atts['revision'] || "0"
                exp_name = procdef.first

                fei = new_fei launchitem, flow_name, flow_revision, exp_name

                RawExpression.new_raw(
                    fei, nil, nil, @application_context, procdef)
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

                parent = fetch_expression fexp.parent_id

                return if parent.class.uses_template?

                parent.raw_children[fexp.fei.child_id.to_i] = 
                   fexp.raw_representation

                parent.store_itself
            end
    end

    #
    # This error is raised when an expression belonging to a paused
    # process is applied or replied to.
    #
    class PausedError < RuntimeError

        attr_reader :wfid

        def initialize (wfid)

            super "process '#{wfid}' is paused"
            @wfid = wfid
        end

        #
        # Returns a hash for this PausedError instance.
        # (simply returns the hash of the paused process' wfid).
        #
        def hash

            @wfid.hash
        end

        #
        # Returns true if the other is a PausedError issued for the
        # same process instance (wfid).
        #
        def == (other)

            return false unless other.is_a?(PausedError)

            (@wfid == other.wfid)
        end
    end

    #--
    # a small help class for storing monitors provided on demand 
    # to expressions that need them
    #
    #class MonitorProvider
    #    include MonitorMixin, Logging
    #    MAX_MONITORS = 10000
    #    def initialize (application_context=nil)
    #        super()
    #        @application_context = application_context
    #        @monitors = LruHash.new(MAX_MONITORS)
    #    end
    #    def [] (key)
    #        synchronize do
    #            (@monitors[key] ||= Monitor.new)
    #        end
    #    end
    #    def delete (key)
    #        synchronize do
    #            #ldebug { "delete() removing Monitor for  #{key}" }
    #            @monitors.delete(key)
    #        end
    #    end
    #end
    #++

end

