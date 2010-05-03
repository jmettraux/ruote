#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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

  #
  # A sort of internal registry, via a shared instance of this class, the worker
  # and the engine can access subservices like parser, treechecker,
  # wfid_generator and so on.
  #
  class Context

    SERVICE_PREFIX = /^s\_/

    attr_reader :storage
    attr_accessor :worker
    attr_accessor :engine

    def initialize (storage, worker_or_engine)

      @storage = storage

      @worker, @engine = if worker_or_engine.kind_of?(Ruote::Engine)
        [ worker_or_engine.worker, worker_or_engine ]
      else
        [ worker_or_engine, nil ]
      end

      initialize_services
    end

    def engine_id

      get_conf['engine_id'] || 'engine'
    end

    def [] (key)

      SERVICE_PREFIX.match(key) ? @services[key] : get_conf[key]
    end

    def []= (key, value)

      raise(
        ArgumentError.new('use context#add_service to register services')
      ) if SERVICE_PREFIX.match(key)

      cf = get_conf
      cf[key] = value
      @storage.put(cf)

      value
    end

    def keys

      get_conf.keys
    end

    def add_service (key, *args)

      path, klass, opts = args

      key = "s_#{key}" unless SERVICE_PREFIX.match(key)

      service = if klass

        require(path)

        aa = [ self ]
        aa << opts if opts

        @services[key] = Ruote.constantize(klass).new(*aa)
      else

        @services[key] = path
      end

      self.class.class_eval %{ def #{key[2..-1]}; @services['#{key}']; end }

      service
    end

    def shutdown

      @storage.shutdown if @storage.respond_to?(:shutdown)
      @worker.shutdown if @worker

      @services.values.each do |s|

        s.shutdown if s.respond_to?(:shutdown)
      end
    end

    # Given a context, a worker, an engine or a storage, will return
    # an instance of Ruote::Context.
    #
    def self.extract (cwes)

      return cwes if cwes.is_a?(Ruote::Context) # context
      return cwes.context if cwes.respond_to?(:context) # worker or engine

      Ruote::Context.new(cwes, nil) # storage
    end

    protected

    def get_conf

      @storage.get_configuration('engine') || {}
    end

    def initialize_services

      @services = {}

      default_conf.merge(get_conf).each do |key, value|

        next unless SERVICE_PREFIX.match(key)

        add_service(key, *value)
      end
    end

    def default_conf

      { 's_wfidgen' => [
          'ruote/id/mnemo_wfid_generator', 'Ruote::MnemoWfidGenerator' ],
        's_parser' => [
          'ruote/parser', 'Ruote::Parser' ],
        's_treechecker' => [
          'ruote/util/treechecker', 'Ruote::TreeChecker' ],
        's_expmap' => [
           'ruote/exp/expression_map', 'Ruote::ExpressionMap' ],
        's_tracker' => [
          'ruote/evt/tracker', 'Ruote::Tracker' ],
        's_plist' => [
          'ruote/part/participant_list', 'Ruote::ParticipantList' ],
        's_dispatch_pool' => [
          'ruote/part/dispatch_pool', 'Ruote::DispatchPool' ],
        's_logger' => [
          'ruote/log/wait_logger', 'Ruote::WaitLogger' ] }
    end
  end
end

