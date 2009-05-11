#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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

require 'ruote/engine/context'
require 'ruote/parser'
require 'ruote/expressions/expression_map'
require 'ruote/expool/wfid_generator'
require 'ruote/expool/expression_pool'
require 'ruote/wqueue/work_queue'


module Ruote

  class Engine

    include EngineContext

    def initialize (context={})

      @context = context

      build_scheduler
      build_parser
      build_expression_map
      build_expression_storage
      build_expression_pool
      build_work_queue
      build_wfid_generator

      build_tree_checker
      build_parser
    end

    def launch (definition, workitem)

      tree = parser.parse(definition)

      expool.apply(tree, nil, workitem)
    end

    protected

    def build_service (name, o)

      service = o.is_a?(Class) ? o.new : o
      service.context = @context if o.respond_to?(:context=)
      @context[name] = service
      #service
    end

    def build_scheduler
      #build_service(:s_scheduler, Rufus::Scheduler.start_new)
    end

    def build_expression_map
      build_service(:s_expression_map, Ruote::ExpressionMap)
    end

    def build_expression_storage
      build_service(:s_expression_storage, Hash)
    end

    def build_expression_pool
      build_service(:s_expression_pool, Ruote::ExpressionPool)
    end

    def build_work_queue
      build_service(:s_work_queue, Ruote::PlainWorkQueue)
    end

    def build_wfid_generator
      build_service(:s_wfid_generator, Ruote::PlainWfidGenerator)
    end

    def build_tree_checker
      #build_service(:s_tree_checker, ...
    end

    def build_parser
      build_service(:s_parser, Ruote::Parser)
    end
  end
end

