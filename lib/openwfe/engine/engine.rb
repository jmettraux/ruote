#--
# Copyright (c) 2006-2009, John Mettraux, Nicolas Modrzyk OpenWFE.org
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

require 'logger'
require 'fileutils'

require 'rufus/scheduler' # gem 'rufus-scheduler'

require 'openwfe/omixins'
require 'openwfe/rudefinitions'
require 'openwfe/service'
require 'openwfe/workitem'
require 'openwfe/util/irb'
require 'openwfe/util/workqueue'
require 'openwfe/util/treechecker'
require 'openwfe/expool/def_parser'
require 'openwfe/expool/wfidgen'
require 'openwfe/expool/expressionpool'
require 'openwfe/expool/expstorage'
require 'openwfe/expool/errorjournal'
require 'openwfe/engine/launch_methods'
require 'openwfe/engine/expool_methods'
require 'openwfe/engine/status_methods'
require 'openwfe/engine/lookup_methods'
require 'openwfe/engine/listener_methods'
require 'openwfe/engine/participant_methods'
require 'openwfe/engine/update_exp_methods'
require 'openwfe/expressions/environment'
require 'openwfe/expressions/expression_map'
require 'openwfe/participants/participant_map'


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
    include LookupMethods
    include ListenerMethods
    include ParticipantMethods
    include UpdateExpMethods
    include LaunchMethods


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
    # By default, this output goes to logs/ruote.log
    #
    def initialize (application_context={})

      super(:s_engine, application_context)

      @engine_name = (application_context[:engine_name] || 'engine').to_s

      $OWFE_LOG = application_context[:logger]

      unless $OWFE_LOG
        FileUtils.mkdir('logs') unless File.exist?('logs')
        $OWFE_LOG = Logger.new('logs/ruote.log', 10, 1024000)
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

      build_tree_checker
        #
        # builds the tree checker (the thing that checks incoming external
        # ruby code for evil things)

      build_def_parser
        #
        # builds the definition parser (the thing that turns process definitions
        # into actual expression trees, ready for execution).

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

      get_expression_pool.reschedule
    end

    alias :reload :reschedule

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

        raise(
          "InFlowWorkitem doesn't belong to a process instance" +
          " nor to a participant")
      end

      return get_expression_pool.launch(workitem) \
        if workitem.is_a?(LaunchItem)
          #
          # launchitem coming from listener
          # let's attempt to launch a new process instance

      raise "engine.reply() cannot handle instances of #{workitem.class}"
    end

    alias :forward :reply
    alias :proceed :reply

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

        if service.respond_to?(:stop)

          service.stop

          linfo { "stop() stopped service '#{sname}' (#{service.class})" }
        end
      end

      linfo { "stop() stopped engine '#{@service_name}'" }

      nil
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

      @application_context[:s_expression_map] = ExpressionMap.new
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

      #init_service(:s_wfid_generator, DefaultWfidGenerator)
      #init_service(:s_wfid_generator, UuidWfidGenerator)
      init_service(:s_wfid_generator, KotobaWfidGenerator)

      #g = FieldWfidGenerator.new(
      #  :s_wfid_generator, @application_context, "wfid")
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

      init_service(:s_workqueue, WorkQueue)
    end

    #
    # Builds the OpenWFEru expression pool (the core of the engine)
    # and binds it in the engine context.
    # There is only one implementation of the expression pool, so
    # this method is usually never overriden.
    #
    def build_expression_pool

      init_service(:s_expression_pool, ExpressionPool)
    end

    #
    # The implementation here builds an InMemoryExpressionStorage
    # instance.
    #
    # See FilePersistedEngine or CachedFilePersistedEngine for
    # overrides of this method.
    #
    def build_expression_storage

      init_service(:s_expression_storage, InMemoryExpressionStorage)
    end

    #
    # The ParticipantMap is a mapping between participant names
    # (well rather regular expressions) and participant implementations
    # (see http://openwferu.rubyforge.org/participants.html)
    #
    def build_participant_map

      init_service(:s_participant_map, ParticipantMap)
    end

    #
    # There is only one Scheduler implementation, that's the one
    # built and bound here.
    #
    def build_scheduler

      @application_context[:s_scheduler] = Rufus::Scheduler.start_new(
        :thread_name =>
        "rufus scheduler for Ruote (engine #{self.object_id})")

      @application_context[:s_scheduler].extend(Logging)

      linfo { "build_scheduler() version is #{Rufus::Scheduler::VERSION}" }
    end

    #
    # The default implementation of this method uses an
    # InMemoryErrorJournal (do not use in production).
    #
    def build_error_journal

      init_service(:s_error_journal, InMemoryErrorJournal)
    end

    #
    # builds the tree checker (see lib/openwfe/util/treechecker.rb)
    #
    def build_tree_checker

      init_service(:s_tree_checker, OpenWFE::TreeChecker)
    end

    #
    # builds the service that turn process definitions into runnable
    # expression trees...
    #
    def build_def_parser

      init_service(:s_def_parser, DefParser)
    end

    #
    # Whether the :no_expstorage_cache is set, a CacheExpressionStorage
    # will be set or not.
    #
    def init_storage (storage_class)

      if @application_context[:no_expstorage_cache]
        init_service(:s_expression_storage, storage_class)
      else
        init_service(:s_expression_storage, CacheExpressionStorage)
        init_service(:s_expression_storage__1, storage_class)
      end
    end
  end

end

