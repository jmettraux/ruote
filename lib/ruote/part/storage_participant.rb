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

require 'ruote/part/local_participant'


module Ruote

  #
  # A participant that stores the workitem in the same storage used by the
  # engine and the worker(s).
  #
  #   part = engine.register_participant 'alfred', Ruote::StorageParticipant
  #
  #   # ... a bit later
  #
  #   puts "workitems still open : "
  #   part.each do |workitem|
  #     puts "#{workitem.fei.wfid} - #{workitem.fields['params']['task']}"
  #   end
  #
  #   # ... when done with a workitem
  #
  #   part.reply(workitem)
  #     # this will remove the workitem from the storage and hand it back
  #     # to the engine
  #
  # Does not thread by default (the engine will not spawn a dedicated thread
  # to handle the delivery to this participant, the workitem will get stored
  # via the main engine thread and basta).
  #
  class StorageParticipant

    include LocalParticipant
    include Enumerable

    def initialize(engine_or_options={}, options=nil)

      if engine_or_options.respond_to?(:context)
        @context = engine_or_options.context
      elsif engine_or_options.is_a?(Ruote::Context)
        @context = engine_or_options
      else
        @options = engine_or_options
      end

      @options ||= {}

      @store_name = @options['store_name']
    end

    # No need for a separate thread when delivering to this participant.
    #
    def do_not_thread; true; end

    # This is the method called by ruote when passing a workitem to
    # this participant.
    #
    def on_workitem

      doc = workitem.to_h

      doc.merge!(
        'type' => 'workitems',
        '_id' => to_id(doc['fei']),
        'participant_name' => doc['participant_name'],
        'wfid' => doc['fei']['wfid'])

      doc['store_name'] = @store_name if @store_name

      @context.storage.put(doc)
    end

    # Used by client code when "saving" a workitem (fields may have changed).
    # Calling #update won't proceed the workitem.
    #
    # Returns nil in case of success, true if the workitem is already gone and
    # the newer version of the workitem if the workitem changed in the mean
    # time.
    #
    def update(workitem)

      r = @context.storage.put(workitem.h)

      r.is_a?(Hash) ? Ruote::Workitem.new(r) : r
    end

    # Added for https://groups.google.com/forum/?fromgroups#!topic/openwferu-users/5bpV2yfKwM0
    #
    # Makes sure the workitem get saved to the storage. Fails if the workitem
    # is already gone.
    # Returns nil in case of success.
    #
    def do_update(workitem=@workitem)

      r = update(workitem)

      fail ArgumentError.new("workitem is gone") if r == true
      return nil if r.nil?

      r.h['fields'] = workitem.fields
      do_update(r)
    end

    # Removes the document/workitem from the storage.
    #
    # Warning: this method is called by the engine (worker), i.e. not by you.
    #
    def on_cancel

      doc = fetch(fei)

      return unless doc

      r = @context.storage.delete(doc)

      on_cancel(fei, flavour) if r != nil
    end

    # Given a fei (or its string version, a sid), returns the corresponding
    # workitem (or nil).
    #
    def [](fei)

      doc = fetch(fei)

      doc ? Ruote::Workitem.new(doc) : nil
    end

    alias by_fei []

    # Removes the workitem from the storage and replies to the engine.
    #
    def proceed(workitem)

      r = remove_workitem('proceed', workitem)

      return proceed(workitem) if r != nil

      workitem.h.delete('_rev')

      reply_to_engine(workitem)
    end

    # Removes the workitem and hands it back to the flow with an error to
    # raise for the participant expression that emitted the workitem.
    #
    def flunk(workitem, err_class_or_instance, *err_arguments)

      r = remove_workitem('reject', workitem)

      return flunk(workitem) if r != nil

      workitem.h.delete('_rev')

      super(workitem, err_class_or_instance, *err_arguments)
    end

    # (soon to be removed)
    #
    def reply(workitem)

      puts '-' * 80
      puts '*** WARNING : please use the Ruote::StorageParticipant#proceed(wi)'
      puts '              instead of #reply(wi) which is deprecated'
      #caller.each { |l| puts l }
      puts '-' * 80

      proceed(workitem)
    end

    # Returns the count of workitems stored in this participant.
    #
    def size

      fetch_all(:count => true)
    end

    # Iterates over the workitems stored in here.
    #
    def each(&block)

      all.each { |wi| block.call(wi) }
    end

    # Returns all the workitems stored in here.
    #
    def all(opts={})

      res = fetch_all(opts)

      res.is_a?(Array) ? res.map { |hwi| Ruote::Workitem.new(hwi) } : res
    end

    # A convenience method (especially when testing), returns the first
    # (only ?) workitem in the participant.
    #
    def first

      wi(fetch_all({}).first)
    end

    # Return all workitems for the specified wfid
    #
    def by_wfid(wfid, opts={})

      if @context.storage.respond_to?(:by_wfid)
        return @context.storage.by_wfid('workitems', wfid, opts)
      end

      wis(@context.storage.get_many('workitems', wfid, opts))
    end

    # Returns all workitems for the specified participant name
    #
    def by_participant(participant_name, opts={})

      return @context.storage.by_participant(
        'workitems', participant_name, opts
      ) if @context.storage.respond_to?(:by_participant)

      do_select(opts) do |hwi|
        hwi['participant_name'] == participant_name
      end
    end

    # field : returns all the workitems with the given field name present.
    #
    # field and value : returns all the workitems with the given field name
    # and the given value for that field.
    #
    # Warning : only some storages are optimized for such queries (like
    # CouchStorage), the others will load all the workitems and then filter
    # them.
    #
    def by_field(field, value=nil, opts={})

      (value, opts = nil, value) if value.is_a?(Hash)

      if @context.storage.respond_to?(:by_field)
        return @context.storage.by_field('workitems', field, value, opts)
      end

      do_select(opts) do |hwi|
        hwi['fields'].keys.include?(field) &&
        (value.nil? || hwi['fields'][field] == value)
      end
    end

    # Queries the store participant for workitems.
    #
    # Some examples :
    #
    #   part.query(:wfid => @wfid).size
    #   part.query('place' => 'nara').size
    #   part.query('place' => 'heiankyou').size
    #   part.query(:wfid => @wfid, :place => 'heiankyou').size
    #
    # There are two 'reserved' criterion : 'wfid' and 'participant'
    # ('participant_name' as well). The rest of the criteria are considered
    # constraints for fields.
    #
    # 'offset' and 'limit' are reserved as well. They should prove useful
    # for pagination. 'skip' can be used instead of 'offset'.
    #
    # Note : the criteria is AND only, you'll have to do ORs (aggregation)
    # by yourself.
    #
    def query(criteria)

      cr = Ruote.keys_to_s(criteria)

      if @context.storage.respond_to?(:query_workitems)
        return @context.storage.query_workitems(cr)
      end

      opts = {}
      opts[:skip] = cr.delete('offset') || cr.delete('skip')
      opts[:limit] = cr.delete('limit')
      opts[:count] = cr.delete('count')

      wfid = cr.delete('wfid')

      count = opts[:count]

      pname = cr.delete('participant_name') || cr.delete('participant')
      opts.delete(:count) if pname

      hwis = wfid ?
        @context.storage.get_many('workitems', wfid, opts) : fetch_all(opts)

      return hwis unless hwis.is_a?(Array)

      hwis = hwis.select { |hwi|
        Ruote::StorageParticipant.matches?(hwi, pname, cr)
      }

      count ? hwis.size : wis(hwis)
    end

    # Cleans this participant out completely
    #
    def purge!

      fetch_all({}).each { |hwi| @context.storage.delete(hwi) }
    end

    # Used by #query when filtering workitems.
    #
    def self.matches?(hwi, pname, criteria)

      return false if pname && hwi['participant_name'] != pname

      fields = hwi['fields']

      criteria.each do |fname, fvalue|
        return false if fields[fname] != fvalue
      end

      true
    end

    # Mostly a test method. Returns a Hash were keys are participant names
    # and values are lists of workitems.
    #
    def per_participant

      each_with_object({}) { |wi, h| (h[wi.participant_name] ||= []) << wi }
    end

    # Mostly a test method. Returns a Hash were keys are participant names
    # and values are integers, the count of workitems for a given participant
    # name.
    #
    def per_participant_count

      per_participant.remap { |(k, v), h| h[k] = v.size }
    end

    # Claims a workitem. Returns the [updated] workitem if successful.
    #
    # Returns nil if the workitem is already reserved.
    #
    # Fails if the workitem can't be found, is gone, or got modified
    # elsewhere.
    #
    # Here is a mini-diagram explaining the reserve/delegate/proceed flow:
    #
    #    in    delegate(nil)    delegate(other)
    #    |    +---------------+ +------+
    #    v    v               | |      v
    #   +-------+  reserve   +----------+  proceed
    #   | ready | ---------> | reserved | ---------> out
    #   +-------+            +----------+
    #
    def reserve(workitem_or_fei, owner)

      hwi = fetch(workitem_or_fei)

      fail ArgumentError.new("workitem not found") if hwi.nil?

      return nil if hwi['owner'] && hwi['owner'] != owner

      hwi['owner'] = owner

      r = @context.storage.put(hwi, :update_rev => true)

      fail ArgumentError.new("workitem is gone") if r == true
      fail ArgumentError.new("workitem got modified meanwhile") if r != nil

      Workitem.new(hwi)
    end

    # Delegates a currently owned workitem to a new owner.
    #
    # Fails if the workitem can't be found, belongs to noone, or if the
    # workitem passed as argument is out of date (got modified in the mean
    # time).
    #
    # It's OK to delegate to nil, thus freeing the workitem.
    #
    # See #reserve for an an explanation of the reserve/delegate/proceed flow.
    #
    def delegate(workitem, new_owner)

      hwi = fetch(workitem)

      fail ArgumentError.new(
        "workitem not found"
      ) if hwi == nil

      fail ArgumentError.new(
        "cannot delegate, workitem doesn't belong to anyone"
      ) if hwi['owner'] == nil

      fail ArgumentError.new(
        "cannot delegate, " +
        "workitem owned by '#{hwi['owner']}', not '#{workitem.owner}'"
      ) if hwi['owner'] != workitem.owner

      hwi['owner'] = new_owner

      r = @context.storage.put(hwi, :update_rev => true)

      fail ArgumentError.new("workitem is gone") if r == true
      fail ArgumentError.new("workitem got modified meanwhile") if r != nil

      Workitem.new(hwi)
    end

    protected

    # Fetches a workitem in its raw form (Hash).
    #
    def fetch(workitem_or_fei)

      hfei = Ruote::FlowExpressionId.extract_h(workitem_or_fei)

      @context.storage.get('workitems', to_id(hfei))
    end

    # Fetches all the workitems. If there is a @store_name, will only fetch
    # the workitems in that store.
    #
    def fetch_all(opts)

      @context.storage.get_many(
        'workitems',
        @store_name ? /^wi!#{@store_name}::/ : nil,
        opts)
    end

    # Given a few options and a block, returns all the workitems that match
    # the block
    #
    def do_select(opts, &block)

      skip = opts[:offset] || opts[:skip]
      limit = opts[:limit]
      count = opts[:count]

      hwis = fetch_all({})
      hwis = hwis.select(&block)

      hwis = hwis[skip..-1] if skip
      hwis = hwis[0, limit] if limit

      return hwis.size if count

      hwis.collect { |hwi| Ruote::Workitem.new(hwi) }
    end

    # Computes the id for the document representing the document in the storage.
    #
    def to_id(fei)

      a = [ Ruote.to_storage_id(fei) ]

      a.unshift(@store_name) if @store_name

      a.unshift('wi')

      a.join('!')
    end

    def wi(hwi)

      hwi ? Ruote::Workitem.new(hwi) : nil
    end

    def wis(workitems_or_count)

      workitems_or_count.is_a?(Array) ?
        workitems_or_count.collect { |wi| Ruote::Workitem.new(wi) } :
        workitems_or_count
    end

    def remove_workitem(action, workitem)

      hwi = fetch(workitem)

      fail ArgumentError.new(
        "cannot #{action}, workitem not found"
      ) if hwi == nil

      fail ArgumentError.new(
        "cannot #{action}, " +
        "workitem is owned by '#{hwi['owner']}', not '#{workitem.owner}'"
      ) if hwi['owner'] && hwi['owner'] != workitem.owner

      r = @context.storage.delete(hwi)

      fail ArgumentError.new(
        "cannot #{action}, workitem is gone"
      ) if r == true

      r
    end
  end
end

