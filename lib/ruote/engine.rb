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
require 'ruote/workitem'
require 'ruote/launchitem'


module Ruote

  class Engine

    attr_reader :storage

    def initialize (worker_or_storage)

      if worker_or_storage.respond_to?(:storage)
        @storage = worker_or_storage.storage
        @context = worker_or_storage.context
        @context.engine = self
      else
        @storage = worker_or_storage
        @context = Ruote::EngineContext.new(self)
      end
    end

    def launch (definition, opts={})

      if definition.is_a?(Launchitem)
        opts[:fields] = definition.fields
        definition = definition.definition
      end

      workitem = Workitem.new(opts[:fields] || {})

      wfid = @context.wfidgen.generate

      @storage.put_task(
        'launch',
        'wfid' => 'wfid',
        'definition' => definition,
        'workitem' => workitem)

      wfid
    end

    #def run
    #  Thread.new { @worker.run }
    #end
    #def stop
    #  @worker.stop
    #end
  end
end

