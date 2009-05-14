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


module Ruote

  module EngineContext

    attr_accessor :context

    alias :ac :context
    alias :application_context :context

    def engine_id
      @context[:engine_id] || 'default'
    end

    def engine
      @context[:s_engine]
    end
    def evhub
      @context[:s_event_hub]
    end
    def pool
      @context[:s_expression_pool]
    end
    def expmap
      @context[:s_expression_map]
    end
    def expstorage
      @context[:s_expression_storage]
    end
    def wqueue
      @context[:s_work_queue]
    end
    def parser
      @context[:s_parser]
    end
    def scheduler
      @context[:s_scheduler]
    end
    def wfidgen
      @context[:s_wfid_generator]
    end
    def pmap
      @context[:s_participant_map]
    end
  end
end

