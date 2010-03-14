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

require 'ruote/storage/base'


module Ruote

  #
  # This storage allows for mixing of storage implementation or simply
  # mixing of storage physical backend.
  #
  #   opts = {}
  #
  #   engine =
  #     Ruote::Engine.new(
  #       Ruote::Worker.new(
  #         Ruote::CompositeStorage.new(
  #           Ruote::FsStorage.new('ruote_work', opts),
  #           'msgs' => Ruote::HashStorage.new(opts))))
  #
  # In this example, everything goes to the FsStorage, except the messages
  # (msgs) that go to an in-memory storage.
  #
  class CompositeStorage

    include StorageBase

    def initialize (default_storage, storages)

      @default_storage = default_storage
      @storages = storages

      prepare_base_methods
    end

    def put (doc, opts={})

      storage(doc['type']).put(doc, opts)
    end

    def get (type, key)

      storage(type).get(type, key)
    end

    def delete (doc)

      storage(type).delete(doc)
    end

    def get_many (type, key=nil, opts={})

      storage(type).get_many(type, key, opts)
    end

    def ids (type)

      storage(type).ids(type)
    end

    def purge!

      TYPES.collect { |t| storage(t) }.uniq.each { |s| s.purge! }
    end

    def purge_type! (type)

      storage(type).purge_type!(type)
    end

    #def add_type (type)
    #end

    protected

    STORAGE_BASE_METHODS = {
      'put_msg' => 'msgs',
      'get_msgs' => 'msgs',
      'find_root_expression' => 'expressions',
      'get_schedules' => 'schedules',
      'put_schedule' => 'schedules'
    }

    TYPES = %w[
      variables
      msgs
      expressions
      errors
      schedules
      configurations
      workitems
    ]

    def prepare_base_methods

      singleton = class << self; self; end

      STORAGE_BASE_METHODS.each do |method, type|

        singleton.send(:define_method, method) do |*args|
          storage(type).send(method, *args)
        end
      end
    end

    def storage (type)

      @storages[type] || @default_storage
    end
  end
end

