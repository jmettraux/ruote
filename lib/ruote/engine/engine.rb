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


#require 'rufus/scheduler' # sudo gem install rufus-scheduler

require 'ruote/parser'
require 'ruote/workitem'
require 'ruote/engine/context'
require 'ruote/engine/process_status'
require 'ruote/engine/misc_methods'
require 'ruote/engine/participant_methods'
require 'ruote/exp/expression_map'
require 'ruote/pool/wfid_generator'
require 'ruote/pool/expression_pool'
require 'ruote/part/participant_map'
require 'ruote/queue/workqueue'
require 'ruote/storage/hash_storage'


module Ruote

  class Engine

    include EngineContext

    include MiscMethods
    include ParticipantMethods


    def initialize (context={})

      @context = context

      @context[:s_engine] = self

      build_work_queue
        # building it first, it's the event hub

      build_scheduler
      build_parser
      build_expression_map
      build_expression_storage
      build_expression_pool
      build_wfid_generator
      build_participant_map

      build_tree_checker
      build_parser
    end

    def launch (definition, opts={})

      tree = parser.parse(definition)

      workitem = Workitem.new(opts[:workitem] || {})

      pool.launch(tree, workitem)
    end

    def reply (workitem)

      pool.reply(workitem)
    end

    def process_status (wfid)

      es = expstorage.find_expressions(:wfid => wfid)
      es.size > 0 ? ProcessStatus.new(es) : nil
    end

    def stop
    end

    def shutdown
      @context.keys.each { |k| remove_service(k) }
    end

    def add_service (key, o)

      remove_service(key)
        # shutdown previous service

      service = o.is_a?(Class) ? o.new : o
      service.context = @context if service.respond_to?(:context=)
      @context[key] = service

      #service
    end

    def remove_service (key)

      service = @context.delete(key)
      service.shutdown if service.respond_to?(:shutdown)
      service.unsubscribe if service.respond_to?(:unsubscribe)

      (service != nil)
    end

    protected

    def build_scheduler
      #add_service(:s_scheduler, Rufus::Scheduler.start_new)
    end

    def build_expression_map
      add_service(:s_expression_map, Ruote::ExpressionMap)
    end

    def build_expression_storage
      add_service(:s_expression_storage, Ruote::HashStorage)
    end

    def build_expression_pool
      add_service(:s_expression_pool, Ruote::ExpressionPool)
    end

    def build_work_queue

      #add_service(:s_work_queue, Ruote::FiberWorkQueue)

      if defined?(EM) && EM.reactor_running?
        add_service(:s_work_queue, Ruote::EmWorkQueue)
      else
        add_service(:s_work_queue, Ruote::ThreadWorkQueue)
      end
    end

    def build_wfid_generator
      add_service(:s_wfid_generator, Ruote::PlainWfidGenerator)
    end

    def build_tree_checker
      #add_service(:s_tree_checker, ...
    end

    def build_parser
      add_service(:s_parser, Ruote::Parser)
    end

    def build_participant_map
      add_service(:s_participant_map, Ruote::ParticipantMap)
    end
  end
end

