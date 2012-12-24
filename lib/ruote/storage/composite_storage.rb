#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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
  #   dashboard =
  #     Ruote::Dashboard.new(
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

    def initialize(default_storage, storages)

      @default_storage = default_storage
      @storages = storages
    end

    # A class method 'delegate', to tell this storage how to deal with
    # each method composing a storage.
    #
    # Followed by a list of 'delegations'.
    #
    def self.delegate(method_name, type=nil)

      if type == nil
        define_method(method_name) do |*args|
          storage_for(args.first['type']).send(method_name, *args)
        end
      elsif type.is_a?(Fixnum)
        define_method(method_name) do |*args|
          storage_for(args[type]).send(method_name, *args)
        end
      else
        type = type.to_s
        define_method(method_name) do |*args|
          storage_for(type).send(method_name, *args)
        end
      end
    end

    delegate :put
    delegate :get, 0
    delegate :get_many, 0
    delegate :delete

    delegate :reserve
    delegate :ids, 0
    delegate :purge_type!, 0
    delegate :empty?, 0

    delegate :put_msg, :msgs
    delegate :get_msgs, :msgs
    delegate :put_schedule, :schedules
    delegate :get_schedules, :schedules
    delegate :delete_schedule, :schedules
    delegate :find_root_expression, :expressions
    delegate :expression_wfids, :expressions
    delegate :get_trackers, :variables
    delegate :get_engine_variable, :variables
    delegate :put_engine_variable, :variables

    # The dilemma for the CompositeStorage with add_type is "to which
    # real storage should the new type get added". The solution: do nothing.
    #
    def add_type(type)
    end

    TYPES = %w[
      variables
      msgs
      expressions
      errors
      schedules
      configurations
      workitems
    ]

    protected

    def storage_for(type)

      @storages[type] || @default_storage
    end
  end
end

