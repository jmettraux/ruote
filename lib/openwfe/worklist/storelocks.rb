#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'thread'
require 'rufus/otime'
require 'openwfe/contextual'


module OpenWFE

  #
  # TODO #11162 : turn this class into a mixin
  #

  #
  # A wrapper for a Store[Participant] that includes a lock system.
  #
  class StoreWithLocks
    include Contextual

    DEFAULT_LOCK_MAX_AGE = "1h"

    attr_accessor :lock_max_age
    attr_reader :store

    #
    # Builds a new store with a lock system wrapping a 'real_store'.
    #
    # This parameter 'real_store' may be a Class, like in
    #
    #   store = StoreWithLocks.new(HashParticipant)
    #
    # You can retrieve the 'real store' with
    #
    #   real_store = store.store
    #
    # By default, a lock is kept for one hour. You can change that
    # value with, for example :
    #
    #   store = StoreWithLocks.new(HashParticipant, :lock_max_age => "30m10s"
    #
    # (setting the lock maximum age to thirty minutes and 10 seconds).
    #
    def initialize (real_store, application_context=nil, params={})

      @store = real_store
      @store = @store.new if @store.kind_of?(Class)

      self.application_context = application_context

      @lock_max_age = params[:lock_max_age] || DEFAULT_LOCK_MAX_AGE
      @lock_max_age = Rufus::parse_time_string @lock_max_age

      @locks = {}
      @lock_mutex = Mutex.new
    end

    #
    # Sets the application context of this store lock and of the
    # real store behind.
    #
    def application_context= (ac)

      @application_context = ac

      if @store.respond_to?(:application_context=) and \
        not store.application_context

        @store.application_context = @application_context
      end
    end

    #
    # Get a workitem, lock it and then return it. Ensures that no other
    # 'locker' can lock it meanwhile.
    #
    def get_and_lock (locker, key)

      @lock_mutex.synchronize do

        object = @store[key]

        return nil unless object

        not_locked?(key)

        @locks[key] = [ locker, Time.now.to_i ]
        object
      end
    end

    alias :lock :get_and_lock

    #
    # Gets a workitem without locking it.
    #
    def get (key)

      @store[key]
    end

    #
    # Removes a lock set on an item.
    # If the item was locked by some other locker, will raise an exception.
    # If the item was not locked, will simply exit silently.
    #
    def release (locker, key)

      @lock_mutex.synchronize do
        holding_lock? locker, key
        @locks.delete key
      end
    end

    #
    # Returns the locker currently holding a given object
    # (known by its key).
    # Will return nil if the object is not locked (or doesn't exist).
    #
    def get_locker (key)

      lock = get_lock key
      return nil unless lock
      lock[0]
    end

    #
    # Saves the workitem and releases the lock on it.
    #
    def save (locker, workitem)

      save_or_forward :save, locker, workitem
    end

    #
    # Forwards the workitem (to the engine) and releases the lock on
    # it (of course, it's not in the store anymore).
    #
    def forward (locker, workitem)

      save_or_forward :forward, locker, workitem
    end

    alias :proceed :forward

    #
    # Directly forwards the list_workitems() call to the wrapped store.
    #
    def list_workitems (workflow_instance_id=nil)

      @store.list_workitems(workflow_instance_id)
    end

    #
    # Returns the count of workitems in the store.
    #
    def size

      @store.size
    end

    #
    # Just calls the consume method of the underlying store.
    #
    def consume (workitem)

      @store.consume workitem
    end

    #
    # Iterates over the workitems in the store.
    #
    # Doesn't care about any order for now.
    #
    def each (&block) # :yields: workitem, locked

      @store.each do |fei, workitem|
        block.call workitem, locked?(fei)
      end
    end

    protected

      def save_or_forward (method, locker, workitem)

        @lock_mutex.synchronize do
          holding_lock? locker, workitem.fei
          @locks.delete workitem.fei
          @store.send method, workitem
        end
      end

      #
      # Returns the lock info (else nil) for the given key.
      #
      def get_lock (key)

        lock = @locks[key]

        return nil unless lock

        l, lt = lock

        if (Time.now.to_i - lt) > @lock_max_age
          @locks.delete key
          return nil
        end

        [ l, lt ]
      end

      #
      # Returns true if the object is locked
      #
      def locked? (key)

        @locks[key] != nil
      end

      #
      # Will raise an exception if the object (designated via its key)
      # is already locked.
      #
      def not_locked? (key)

        raise "already locked" if get_lock key
      end

      #
      # Will raise an exception if the locker is not holding a lock
      # for the given key.
      #
      def holding_lock? (locker, key)

        lock = get_lock key
        raise "not locked" unless lock
        l, lt = lock
        raise "locked by someone else" if (l != locker)
        # else, simply end
      end

      #--
      # Sets the lock on a given key to 'now'.
      #
      #def touch_lock (key)
      #  lock = @locks[key]
      #  return false unless lock
      #  locker, lock_time = lock
      #  @locks[key] = [ locker, Time.now.to_i ]
      #  true
      #end
      #++
  end
end

