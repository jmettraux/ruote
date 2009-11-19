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

require 'ruote/util/misc'


module Ruote

  class Context

    attr_reader :storage

    def initialize (storage)

      @storage = storage

      @conf = default_conf.merge(@storage.get('configuration', 'engine') || {})

      initialize_services
    end

    def [] (key)

      @conf[key]
    end

    def add_service (key, path, klass)

      require(path)

      @conf[key] = Ruote.constantize(klass).new(self)

      self.class.class_eval %{ def #{key[2..-1]}; @conf['#{key}']; end }
    end

    def shutdown

      @conf.values.each do |s|

        s.shutdown if s.respond_to?(:shutdown)
      end
    end

    protected

    def initialize_services

      @conf.keys.each do |key|

        next unless key.match(/^s\_/)

        path, klass = @conf[key]

        add_service(key, path, klass)
      end
    end

    def default_conf

      {
        's_wfidgen' => [ 'ruote/id/wfid_generator', 'Ruote::WfidGenerator' ],
        's_parser' => [ 'ruote/parser', 'Ruote::Parser' ],
        's_treechecker' => [ 'ruote/util/treechecker', 'Ruote::TreeChecker' ]
      }
    end
  end

  class EngineContext < Context

    attr_reader :engine

    def initialize (engine)

      @engine = engine

      super(@engine.storage)
    end
  end

  class WorkerContext < Context

    attr_reader :worker
    attr_accessor :engine

    def initialize (worker)

      @worker = worker
      @engine = nil

      super(@worker.storage)
    end

    protected

    def default_conf

      super.merge(
        's_plist' => [
          'ruote/part/participant_list', 'Ruote::ParticipantList' ],
        's_expmap' => [
          'ruote/exp/expression_map', 'Ruote::ExpressionMap' ])
    end
  end
end

