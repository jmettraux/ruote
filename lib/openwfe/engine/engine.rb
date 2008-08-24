#
#--
# Copyright (c) 2006-2008, John Mettraux, Nicolas Modrzyk OpenWFE.org
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
# Nicolas Modrzyk at openwfe.org
#

require 'logger'
require 'fileutils'

require 'rufus/scheduler' # gem 'rufus-scheduler'

require 'openwfe/omixins'
require 'openwfe/rudefinitions'
require 'openwfe/service'
require 'openwfe/workitem'
require 'openwfe/util/irb'
require 'openwfe/util/workqueue'
require 'openwfe/expool/wfidgen'
require 'openwfe/expool/expressionpool'
require 'openwfe/expool/expstorage'
require 'openwfe/expool/errorjournal'
require 'openwfe/engine/expool_methods'
require 'openwfe/engine/status_methods'
require 'openwfe/engine/participant_methods'
require 'openwfe/engine/update_exp_methods'
require 'openwfe/expressions/environment'
require 'openwfe/expressions/expressionmap'
require 'openwfe/participants/participantmap'


module OpenWFE

  #
  # The simplest implementation of the OpenWFE workflow engine.
  # No persistence is used, everything is stored in memory.
  #
  class Engine < Service

    include OwfeServiceLocator
    include FeiMixin

    include ExpoolMethods
    include StatusMethods
    include ParticipantMethods
    include UpdateExpMethods


    #
    # The name of the engine, will be used to 'stamp' each expression
    # active in the engine (and thus indirectrly, each workitem)
    #
    attr_reader :engine_name

    #
    # Builds an OpenWFEru engine.
    #
    # Accepts an optional initial application_context (containing
    # initialization params for services for example).
    #
    # The engine itself uses one param :logger, used to define
    # where all the log output for OpenWFEru should go.
    # By default, this output goes to logs/openwferu.log
    #
    def initialize (application_context={})

      super S_ENGINE, application_context

      @engine_name = application_context[:engine_name] || 'engine'

      $OWFE_LOG = application_context[:logger]

      unless $OWFE_LOG
        #puts "Creating logs in " + FileUtils.pwd
        FileUtils.mkdir("logs") unless File.exist?("logs")
        $OWFE_LOG = Logger.new "logs/openwferu.log", 10, 1024000
        $OWFE_LOG.level = Logger::INFO
      end

      # build order matters.
      #
      # especially for the expstorage which 'observes' the expression
      # pool and thus needs to be instantiated after it.

      build_scheduler
        #
        # for delayed or repetitive executions (it's the engine's clock)
        # see http://openwferu.rubyforge.org/scheduler.html

      build_expression_map
        #
        # mapping expression names ('sequence', 'if', 'concurrence',
        # 'when'...) to their implementations (SequenceExpression,
        # IfExpression, ConcurrenceExpression, ...)

      build_wfid_generator
        #
        # the workflow instance (process instance) id generator
        # making sure each process instance has a unique identifier

      build_workqueue
        #
        # where apply/reply get queued and processed asynchronously
        # by a single thread

      build_expression_pool
        #
        # the core (hairy ball) of the engine

      build_expression_storage
        #
        # the engine persistence (persisting the expression instances
        # that make up process instances)

      build_participant_map
        #
        # building the services that maps participant names to
        # participant implementations / instances.

      build_error_journal
        #
        # builds the error journal (keeping track of failures
        # in business process executions, and an opportunity to
        # fix and replay)

      linfo { "new() --- engine started --- #{self.object_id}" }
    end

    #
    # Call this method once the participants for a persisted engine
    # have been [re]added.
    #
    # If this method is called too soon, missing participants will
    # cause trouble... Call this method after all the participants
    # have been added.
    #
    def reschedule

      get_expression_pool.reschedule()
    end

    alias :reload :reschedule

    #
    # When 'parameters' are used at the top of a process definition, this
    # method can be used to assert a launchitem before launch.
    # An expression will be raised if the parameters do not match the
    # requirements.
    #
    # Note that the launch method will raise those exceptions as well.
    # This method can be useful in some scenarii though.
    #
    def pre_launch_check (launchitem)

      get_expression_pool.prepare_raw_expression(launchitem)
    end

    #
    # Launches a [business] process.
    # The 'launch_object' param may contain either a LaunchItem instance,
    # either a String containing the URL of the process definition
    # to launch (with an empty LaunchItem created on the fly).
    #
    # The launch object can also be a String containing the XML process
    # definition or directly a class extending OpenWFE::ProcessDefinition
    # (Ruby process definition).
    #
    # Returns the FlowExpressionId instance of the expression at the
    # root of the newly launched process.
    #
    # Options for scheduled launches like :at, :in and :cron are accepted
    # via the 'options' optional parameter.
    # For example :
    #
    #   engine.launch(launch_item)
    #     # will launch immediately
    #
    #   engine.launch(launch_item, :in => "1d20m")
    #     # will launch in one day and twenty minutes
    #
    #   engine.launch(launch_item, :at => "Tue Sep 11 20:23:02 +0900 2007")
    #     # will launch at that point in time
    #
    #   engine.launch(launch_item, :cron => "0 5 * * *")
    #     # will launch that same process every day,
    #     # five minutes after midnight (see "man 5 crontab")
    #
    # === :wait_for
    #
    # If you really need that, you can launch a process and wait for its
    # termination (or cancellation or error) as in :
    #
    #   engine.launch(launch_item, :wait_for => true)
    #     # will launch and return only when the process is over
    #
    # Note that if you set the option :wait_for to true, a triplet will
    # be returned instead of just a FlowExpressionId.
    #
    # This triplet is composed of [ message, info, fei ]
    # where message is :terminate, :error or :cancel and info contains
    # either the workitem, the error or a wfid, respectively.
    #
    # See http://groups.google.com/group/openwferu-users/browse_frm/thread/ffd0589bdc877765 for more about this triplet.
    #
    # (Note that the current implementation of this :wait_for will return if
    # any error was found. Thus, if an error occurs in a concurrent branch
    # and the other branch goes on, the launch() will return, even if the
    # rest of the process is continuing).
    #
    def launch (launch_object, options={})

      launchitem = extract_launchitem launch_object

      fei = get_expression_pool.launch launchitem, options

      #linfo { "launch() #{fei.wfid} : #{fei.wfname} #{fei.wfrevision}" }

      fei.dup
        #
        # so that users of this launch() method can play with their
        # fei without breaking things
    end

    #
    # This method is used to feed a workitem back to the engine (after
    # it got sent to a worklist or wherever by a participant).
    # Participant implementations themselves do call this method usually.
    #
    # This method also accepts LaunchItem instances.
    #
    # Since OpenWFEru 0.9.16, this reply method accepts InFlowWorkitem
    # that don't belong to a process instance (ie whose flow_expression_id
    # is nil). It will simply notify the participant_map of the reply
    # for the given participant_name. If there is no participant_name
    # specified for this orphan workitem, an exception will be raised.
    #
    def reply (workitem)

      if workitem.is_a?(InFlowWorkItem)

        if workitem.flow_expression_id
          #
          # vanilla case, workitem coming back
          # (from listener probably)

          return get_expression_pool.reply(
            workitem.flow_expression_id, workitem)
        end

        if workitem.participant_name
          #
          # a workitem that doesn't belong to a process instance
          # but bears a participant name.
          # Notify, there may be something listening on
          # this channel (see the 'listen' expression).

          return get_participant_map.onotify(
            workitem.participant_name, :reply, workitem)
        end

        raise \
          "InFlowWorkitem doesn't belong to a process instance" +
          " nor to a participant"
      end

      return get_expression_pool.launch(workitem) \
        if workitem.is_a?(LaunchItem)
          #
          # launchitem coming from listener
          # let's attempt to launch a new process instance

      raise \
        "engine.reply() " +
        "cannot handle instances of #{workitem.class}"
    end

    alias :forward :reply
    alias :proceed :reply

    #
    # Adds a workitem listener to this engine.
    #
    # The 'freq' parameters if present might indicate how frequently
    # the resource should be polled for incoming workitems.
    #
    #   engine.add_workitem_listener(listener, "3m10s")
    #    # every 3 minutes and 10 seconds
    #
    #   engine.add_workitem_listener(listener, "0 22 * * 1-5")
    #    # every weekday at 10pm
    #
    # TODO : block handling...
    #
    def add_workitem_listener (listener, freq=nil)

      name = nil

      if listener.kind_of?(Class)

        listener = init_service nil, listener

        name = listener.service_name
      else

        name = listener.name if listener.respond_to?(:name)
        name = "#{listener.class}::#{listener.object_id}" unless name

        @application_context[name] = listener
      end

      result = nil

      if freq

        freq = freq.to_s.strip

        result = if Rufus::Scheduler.is_cron_string(freq)

          get_scheduler.schedule(freq, listener)
        else

          get_scheduler.schedule_every(freq, listener)
        end
      end

      linfo { "add_workitem_listener() added '#{name}'" }

      result
    end

    #
    # Makes the current thread join the engine's scheduler thread
    #
    # You can thus make an engine standalone with something like :
    #
    #   require 'openwfe/engine/engine'
    #
    #   the_engine = OpenWFE::Engine.new
    #   the_engine.join
    #
    # And you'll have to hit CTRL-C to make it stop.
    #
    def join

      get_scheduler.join
    end

    #
    # Calling this method makes the control flow block until the
    # workflow engine is inactive.
    #
    # TODO : implement idle_for
    #
    def join_until_idle

      storage = get_expression_storage

      while storage.size > 1
        sleep 1
      end
    end

    #
    # Enabling the console means that hitting CTRL-C on the window /
    # term / dos box / whatever does run the OpenWFEru engine will
    # open an IRB interactive console for directly manipulating the
    # engine instance.
    #
    # Hit CTRL-D to get out of the console.
    #
    def enable_irb_console

      OpenWFE::trap_int_irb(binding)
    end

    #--
    # Makes sure that hitting CTRL-C will actually kill the engine VM and
    # not open an IRB console.
    #
    #def disable_irb_console
    #  $openwfe_irb = nil
    #  trap 'INT' do
    #    exit 0
    #  end
    #end
    #++

    #
    # Stopping the engine will stop all the services in the
    # application context.
    #
    def stop

      linfo { "stop() stopping engine '#{@service_name}'" }

      @application_context.each do |sname, service|

        next if sname == self.service_name

        #if service.kind_of?(ServiceMixin)
        if service.respond_to?(:stop)

          service.stop

          linfo do
            "stop() stopped service '#{sname}' (#{service.class})"
          end
        end
      end

      linfo { "stop() stopped engine '#{@service_name}'" }

      nil
    end

    #
    # Waits for a given process instance to terminate.
    # The method only exits when the flow terminates, but beware : if
    # the process already terminated, the method will never exit.
    #
    # The parameter can be a FlowExpressionId instance, for example the
    # one given back by a launch(), or directly a workflow instance id
    # (String).
    #
    # This method is mainly used in utests.
    #
    def wait_for (fei_or_wfid)

      wfid = if fei_or_wfid.kind_of?(FlowExpressionId)
        fei_or_wfid.workflow_instance_id
      else
        fei_or_wfid
      end

      get_expression_pool.send :wait_for, wfid
    end

    #
    # Looks up a process variable in a process.
    # If fei_or_wfid is not given, will simply look in the
    # 'engine environment' (where the top level variables '//' do reside).
    #
    def lookup_variable (var_name, fei_or_wfid=nil)

      return get_expression_pool.fetch_engine_environment[var_name] \
        unless fei_or_wfid

      fetch_exp(fei_or_wfid).lookup_variable var_name
    end

    #
    # Returns the variables set for a process or an expression.
    #
    # If a process (wfid) is given, variables of the process environment
    # will be returned, else variables in the environment valid for the
    # expression (fei) will be returned.
    #
    # If nothing (or nil) is given, the variables set in the engine
    # environment will be returned.
    #
    def get_variables (fei_or_wfid=nil)

      return get_expression_pool.fetch_engine_environment.variables \
        unless fei_or_wfid

      fetch_exp(fei_or_wfid).get_environment.variables
    end

    #
    # Returns an array of wfid (workflow instance ids) whose root
    # environment contains the given variable
    #
    # If there are no matches, an empty array will be returned.
    #
    # Regular expressions are accepted as values.
    #
    # If no value is given, all processes with the given variable name
    # set will be returned.
    #
    def lookup_processes (var_name, value=nil)

      # TODO : maybe this would be better in the ExpressionPool

      regexp = value.is_a?(Regexp) ? value : nil

      envs = get_expression_storage.find_expressions(
        :include_classes => Environment)

      envs = envs.find_all do |env|

        val = env.variables[var_name]

        #(val and ((not regexp) or (regexp.match(val))))
        if val != nil
          if regexp
            regexp.match(val)
          elsif value
            val == value
          else
            true
          end
        else
          false
        end
      end

      envs.collect { |env| env.fei.wfid }

      #envs.inject([]) do |r, env|
      #  val = env.variables[var_name]
      #  r << env.fei.wfid \
      #    if (val and ((not regexp) or (regexp.match(val))))
      #  r
      #end
        #
        # seems slower...
    end

    protected

      #--
      # the following methods may get overridden upon extension
      # see for example file_persisted_engine.rb
      #++

      #
      # Builds the ExpressionMap (the mapping between expression names
      # and expression implementations).
      #
      def build_expression_map

        @application_context[S_EXPRESSION_MAP] = ExpressionMap.new
          #
          # the expression map is not a Service anymore,
          # it's a simple instance (that will be reused in other
          # OpenWFEru components)
      end

      #
      # This implementation builds a KotobaWfidGenerator instance and
      # binds it in the engine context.
      # There are other WfidGeneration implementations available, like
      # UuidWfidGenerator or FieldWfidGenerator.
      #
      def build_wfid_generator

        #init_service S_WFID_GENERATOR, DefaultWfidGenerator
        #init_service S_WFID_GENERATOR, UuidWfidGenerator
        init_service S_WFID_GENERATOR, KotobaWfidGenerator

        #g = FieldWfidGenerator.new(
        #  S_WFID_GENERATOR, @application_context, "wfid")
          #
          # showing how to initialize a FieldWfidGenerator that
          # will take as workflow instance id the value found in
          # the field "wfid" of the LaunchItem.
      end

      #
      # Builds the workqueue where apply/reply work is queued
      # and processed.
      #
      def build_workqueue

        init_service S_WORKQUEUE, WorkQueue
      end

      #
      # Builds the OpenWFEru expression pool (the core of the engine)
      # and binds it in the engine context.
      # There is only one implementation of the expression pool, so
      # this method is usually never overriden.
      #
      def build_expression_pool

        init_service S_EXPRESSION_POOL, ExpressionPool
      end

      #
      # The implementation here builds an InMemoryExpressionStorage
      # instance.
      #
      # See FilePersistedEngine or CachedFilePersistedEngine for
      # overrides of this method.
      #
      def build_expression_storage

        init_service S_EXPRESSION_STORAGE, InMemoryExpressionStorage
      end

      #
      # The ParticipantMap is a mapping between participant names
      # (well rather regular expressions) and participant implementations
      # (see http://openwferu.rubyforge.org/participants.html)
      #
      def build_participant_map

        init_service S_PARTICIPANT_MAP, ParticipantMap
      end

      #
      # There is only one Scheduler implementation, that's the one
      # built and bound here.
      #
      def build_scheduler

        @application_context[S_SCHEDULER] = Rufus::Scheduler.start_new(
          :thread_name =>
          "rufus scheduler for Ruote (engine #{self.object_id})")

        @application_context[S_SCHEDULER].extend Logging

        linfo { "build_scheduler() version is #{Rufus::Scheduler::VERSION}" }
      end

      #
      # The default implementation of this method uses an
      # InMemoryErrorJournal (do not use in production).
      #
      def build_error_journal

        init_service S_ERROR_JOURNAL, InMemoryErrorJournal
      end

      #
      # Turns the raw launch request info into a LaunchItem instance.
      #
      def extract_launchitem (launch_object)

        if launch_object.kind_of?(OpenWFE::LaunchItem)

          launch_object

        elsif launch_object.kind_of?(Class)

          LaunchItem.new launch_object

        elsif launch_object.kind_of?(String)

          li = OpenWFE::LaunchItem.new

          if launch_object[0, 1] == '<' or launch_object.index("\n")

            li.workflow_definition_url = "field:__definition"
            li['__definition'] = launch_object

          else

            li.workflow_definition_url = launch_object
          end

          li
        end
      end
  end

end

