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


require 'ruote/parser'
require 'ruote/workitem'
require 'ruote/launchitem'
require 'ruote/engine/context'
require 'ruote/engine/process_status'
require 'ruote/engine/participant_methods'
require 'ruote/engine/listener_methods'
require 'ruote/exp/expression_map'
require 'ruote/pool/mnemo_wfid_generator'
require 'ruote/pool/expression_pool'
require 'ruote/part/participant_list'
require 'ruote/queue/thread_workqueue'
require 'ruote/storage/hash_storage'
require 'ruote/storage/cache_storage'
require 'ruote/err/ejournal'
require 'ruote/evt/tracker'
require 'ruote/time/scheduler'


module Ruote

  VERSION = '2.0.0'

  class Engine

    include EngineContext
    include ParticipantMethods
    include ListenerMethods

    attr_reader :engine_id


    def initialize (context={})

      @context = context

      @engine_id = @context[:engine_id] || 'engine'

      @context[:s_engine] = self

      build_workqueue
        # building it first, it's the event hub

      build_expression_map
      build_expression_storage
      build_expression_pool
      build_wfid_generator
      build_participant_list
      build_error_journal

      build_treechecker
      build_parser

      build_tracker
      build_scheduler
    end

    def launch (definition, opts={})

      if definition.is_a?(Launchitem)
        opts[:fields] = definition.fields
        definition = definition.definition
      end

      tree = parser.parse(definition)

      workitem = Workitem.new(opts[:fields] || {})

      wfid = wfidgen.generate

      wqueue.emit(
        :processes, :launch,
        :wfid => wfid,
        :tree => tree,
        :workitem => workitem)

      wfid
    end

    # Use this method to pipe back workitems into the engine (workitems
    # coming back from a[n external] participant.
    #
    def reply (workitem)

      wqueue.emit(
        :workitems, :received,
        :workitem => workitem, :pname => workitem.participant_name)

      pool.reply(workitem)
    end

    # Use in case of stalled expression (mainly participant expression),
    # re-applies the given expression.
    #
    # If the optional cancel parameter is set to true, this method
    # cancel the expression and then re-apply it.
    #
    def re_apply (fei, cancel=false)

      pool.re_apply(fei, cancel)
    end

    # Returns the status of a process instance, takes as input the process
    # instance id (workflow instance id).
    # Returns nil the process doesn't exist or has already terminated.
    #
    def process (wfid)

      exps = expstorage.find_expressions(:wfid => wfid)
      errs = ejournal.process_errors(wfid)

      # NOTE : should we return a process status if there are only errors ?
      # (no expressions ?)

      exps.size > 0 ? ProcessStatus.new(exps, errs) : nil
    end

    # Returns a list of all the processes currently running in the engine.
    # (Array of ProcessStatus instances).
    #
    def processes

      exps = expstorage.find_expressions

      ps = exps.inject({}) do |h, exp|
        (h[exp.fei.parent_wfid] ||= []) << exp
        h
      end

      ps.collect do |wfid, exps|
        ProcessStatus.new(exps, ejournal.process_errors(wfid))
      end
    end

    # Cancels a whole process instance.
    #
    def cancel_process (wfid)

      wqueue.emit(:processes, :cancel, :wfid => wfid)
    end

    # Kills a whole process instance. Like a cancel, but no "on_cancel" is
    # triggered.
    #
    def kill_process (wfid)

      wqueue.emit(:processes, :kill, :wfid => wfid)
    end

    # Cancels an expression (and all its children).
    #
    def cancel_expression (fei)

      pool.cancel_expression(fei, nil)
    end

    # Cancels an expression (and all its children), but makes sure that
    # no on_cancel block is called (hence the 'kill' label).
    #
    def kill_expression (fei)

      pool.cancel_expression(fei, :kill)
    end

    # Simply reemits the message (queue event) found in the error..
    #
    def replay_at_error (err)

      ejournal.replay_at_error(err)
    end

    def stop

      # TODO
      # stop != shutdown
    end

    def shutdown

      @context.values.each do |service|
        next if service == self
        service.shutdown if service.respond_to?(:shutdown)
        service.unsubscribe if service.respond_to?(:unsubscribe)
      end
    end

    def add_service (key, o)

      remove_service(key)
        # shutdown previous service

      service = o.is_a?(Class) ? o.new : o

      @context[key] = service

      service.context = @context if service.respond_to?(:context=)

      #service
    end

    def remove_service (key)

      service = @context.delete(key)
      service.shutdown if service.respond_to?(:shutdown)
      service.unsubscribe if service.respond_to?(:unsubscribe)

      (service != nil)
    end

    #
    # Loads a process definition from a path or a URL
    #
    def load_definition (path)

      parser.parse(path)
    end

    protected

    def build_scheduler
      add_service(:s_scheduler, Ruote::Scheduler)
    end

    def build_expression_map
      add_service(:s_expression_map, Ruote::ExpressionMap)
    end

    def build_expression_storage
      init_storage(Ruote::HashStorage)
    end

    def build_expression_pool
      add_service(:s_expression_pool, Ruote::ExpressionPool)
    end

    def build_workqueue

      #add_service(:s_workqueue, Ruote::FiberWorkqueue)

      if defined?(EM) && EM.reactor_running?
        require 'ruote/queue/em_workqueue'
        add_service(:s_workqueue, Ruote::EmWorkqueue)
      else
        add_service(:s_workqueue, Ruote::ThreadWorkqueue)
        #require 'ruote/queue/fiber_workqueue'
        #add_service(:s_workqueue, Ruote::FiberWorkqueue)
      end
    end

    def build_wfid_generator
      #add_service(:s_wfid_generator, Ruote::WfidGenerator)
      add_service(:s_wfid_generator, Ruote::MnemoWfidGenerator)
    end

    def build_treechecker
      add_service(:s_treechecker, Ruote::TreeChecker)
    end

    def build_parser
      add_service(:s_parser, Ruote::Parser)
    end

    def build_participant_list
      add_service(:s_participant_list, Ruote::ParticipantList)
    end

    def build_error_journal
      add_service(:s_ejournal, Ruote::HashErrorJournal)
    end

    def build_tracker
      add_service(:s_tracker, Ruote::Tracker)
    end

    def init_storage (storage_class)

      if storage_class == Ruote::HashStorage || context[:no_expstorage_cache]
        add_service(:s_expression_storage, storage_class)
      else
        add_service(:s_expression_storage, Ruote::CacheStorage)
        add_service(:s_expression_storage__1, storage_class)
      end
    end
  end
end

