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


require 'openwfe/engine/engine'
require 'openwfe/participants/participant'


module OpenWFE

  #
  # An OpenWFEja-style worklist.
  #
  class Worklist
    include LocalParticipant

    attr_reader :stores

    #
    # Builds a new worklist.
    #
    # Parameters are :
    #
    # - :auth_system : something with an authenticate(user, pass) and an
    #   optional authorised?(user, store, action) methods.
    # - :launchables : an array of URLs : launchables, in this basic
    #   implementation, all users share the same list
    #
    def initialize (application_context, params)

      @application_context = application_context

      as = params[:auth_system]

      @auth_system = if as == nil
        DefaultAuthSystem.new
      elsif as.kind_of?(Hash)
        DefaultAuthSystem.new(as)
      else
        as
      end

      @stores = []
    end

    def consume (workitem)

      pname = workitem.participant_name

      each_store do |regex, store_name, store|

        next unless pname.match regex

        store.consume workitem
        break
      end
    end

    #
    # A simple call to the authentify method of the @auth_system
    # passed a initialization time.
    #
    def authenticate (user, pass)
      @auth_system.authenticate(user, pass)
    end

    #
    # Returns a string like "rwd" or "rw" or even "".
    #
    # Read / Write / Delegate
    #
    def get_permissions (user, store_name)
      s = ""
      [ :read, :write, :delegate ].each do |action|
        s << action.to_s[0, 1] \
          if @auth_system.authorized?(user, store_name, action)
      end
      s
    end

    #
    # For now, just a shortcut for
    #
    #   @stores << [ regex, store_name, store]
    #
    def add_store (regex, store_name, store)

      @stores << [ regex, store_name, store]

      store.application_context = @application_context \
        if store.respond_to?(:application_context=)
    end

    #
    # Well, this implementation just returns workitems
    #
    def get_headers (user, store_name, limit)

      authorized?(user, store_name, :read)

      l = []

      get_store(store_name).each do |workitem, locked|
        break if limit and l.size >= limit
        l << [ workitem, locked ]
      end

      l
    end

    def get (user, store_name, fei)
      authorized?(user, store_name, :read)
      get_store(store_name).get(fei)
    end
    def get_and_lock (user, store_name, fei)
      authorized?(user, store_name, :write)
      get_store(store_name).get_and_lock(user, fei)
    end

    def release (user, store_name, wi_or_fei)

      authorized?(user, store_name, :write)

      fei = wi_or_fei
      fei = fei.fei if fei.respond_to?(:fei)

      get_store(store_name).release(user, fei)
    end

    def save (user, store_name, workitem)
      authorized?(user, store_name, :write)
      get_store(store_name).save(user, workitem)
    end
    def forward (user, store_name, workitem)
      authorized?(user, store_name, :write)
      get_store(store_name).forward(user, workitem)
    end
    def list_workitems (user, store_name, workflow_instance_id=nil)
      authorized?(user, store_name, :read)
      get_store(store_name).list_workitems(workflow_instance_id)
    end

    def delegate (user, from_store_name, to_store_name)
      authorized?(user, from_store_name, :write)
      authorized?(user, to_store_name, :write)
      # TODO : continue me
    end

    #
    # Iterates over each of the stores in this worklist.
    #
    def each_store (&block) # :yields: regex, store_name, store

      return unless block

      @stores.each do |v|
        regex, store_name, store = v
        block.call regex, store_name, store
      end
    end

    #
    # Returns the first store whose regex matches the given
    # store_name.
    #
    def lookup_store (store_name)
      each_store do |regex, name, store|
        return store if regex.match store_name
      end
      nil
    end

    #
    # Returns the store instance with the given name.
    #
    def get_store (store_name)
      each_store do |regex, s_name, store|
        return store if s_name == store_name
      end
      nil
    end

    #
    # Not really the job of a worklist, but it was in OpenWFEja, so
    # here it is...
    #
    def launch_flow (engine_name, launch_item)

      e = lookup_engine engine_name

      raise "couldn't find engine named '#{engine_name}'" unless e

      if e.is_a? OpenWFE::Engine

        e.launch launch_item

      elsif e.is_a? OpenWFE::Participant

        e.consume launch_item

      else
        raise \
          "cannot launch a flow via something of "+
          "class #{e.class.name}"
      end
    end

    protected

      #
      # This method is called when a launch_flow request is coming,
      # it will lookup in the participant map to find the way (the
      # Participant implementation) to deliver the launch_item to the
      # engine.
      #
      # If there is no engine with that name, the default (local) engine
      # is returned (and will thus be used to launch the flow).
      #
      def lookup_engine (engine_name)
        e = get_participant_map.lookup_participant engine_name
        return e if e
        get_engine
      end

      def authorized? (user, store_name, action)

        return true unless @auth_system.respond_to?(:authorized?)

        unless @auth_system.authorized?(user, store_name, action)
          raise \
            "'#{user}' is not authorized " +
            "to '#{action}' on store '#{store_name}'"
        end

        true
      end
  end

  class DefaultAuthSystem

    def initialize (hash=nil)
      @hash = hash
    end

    def authenticate (user, pass)
      return true unless @hash
      pass == @hash[user]
    end

    def authorized? (user, store_name, action)
      return true unless @hash
      @hash[user] != nil
    end
  end

  #--
  # persistence...
  # is handled by the StoreParticipant implementations themselves
  #++

end

