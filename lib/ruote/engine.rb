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

require 'ruote/context'
require 'ruote/launchitem'
require 'ruote/engine/process_status'


module Ruote

  class Engine

    require 'ruote/engine/ro_participant'

    attr_reader :storage
    attr_reader :context
    attr_reader :variables

    def initialize (worker_or_storage)

      if worker_or_storage.respond_to?(:context)

        @storage = worker_or_storage.storage
        @context = worker_or_storage.context
        @context.engine = self

        Thread.abort_on_exception = true
        Thread.new { @context.worker.run }

      else

        @storage = worker_or_storage
        @context = Ruote::EngineContext.new(self)
      end

      @variables = EngineVariables.new(@storage)
    end

    def launch (definition, opts={})

      if definition.is_a?(Launchitem)
        opts[:fields] = definition.fields
        definition = definition.definition
      end

      tree = @context.parser.parse(definition)

      workitem = { 'fields' => opts[:fields] || {} }

      wfid = @context.wfidgen.generate

      @storage.put_task(
        'launch',
        'wfid' => wfid,
        'tree' => tree,
        'workitem' => workitem,
        'variables' => {})

      wfid
    end

    def cancel_process (wfid)

      @storage.put_task(
        'cancel_process',
        'wfid' => wfid)
    end

    def kill_process (wfid)

      raise "wire me !"

      @storage.put_task(
        'kill_process',
        'wfid' => wfid)
    end

    def process (wfid)

      exps = @storage.get_many('expressions', /#{wfid}$/)

      return nil if exps.size < 1

      ProcessStatus.new(
        @context, exps, @storage.get_many('errors', /#{wfid}$/))
    end

    def purge!

      @storage.purge!
    end

    def shutdown

      @context.shutdown
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

      @storage.get('misc', 'variables')[k]
    end

    def []= (k, v)

      vars = @storage.get('misc', 'variables') || {
        'type' => 'misc', '_id' => 'variables'
      }

      vars[k] = v

      self.[]=(k, v) if @storage.put(vars)
        # redo it if the put failed
    end
  end
end

