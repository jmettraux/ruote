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

    attr_accessor :context

    def initialize (engine_or_options={}, options=nil)

      if engine_or_options.respond_to?(:context)
        @context = engine_or_options.context
      elsif engine_or_options.is_a?(Ruote::Context)
        @context = engine_or_options
      else
        options = engine_or_options
      end

      options ||= {}

      @store_name = options['store_name']
    end

    # No need for a separate thread when delivering to this participant.
    #
    def do_not_thread; true; end

    def consume (workitem)

      doc = workitem.to_h

      doc.merge!(
        'type' => 'workitems',
        '_id' => to_id(doc['fei']),
        'participant_name' => doc['participant_name'],
        'wfid' => doc['fei']['wfid'])

      doc['store_name'] = @store_name if @store_name

      @context.storage.put(doc)
    end
    alias :update :consume

    # Removes the document/workitem from the storage
    #
    def cancel (fei, flavour)

      doc = fetch(fei)

      r = @context.storage.delete(doc)

      cancel(fei, flavour) if r != nil
    end

    def [] (fei)

      doc = fetch(fei)

      doc ? Ruote::Workitem.new(doc) : nil
    end

    def fetch (fei)

      hfei = Ruote::FlowExpressionId.extract_h(fei)

      @context.storage.get('workitems', to_id(hfei))
    end

    # Removes the workitem from the in-memory hash and replies to the engine.
    #
    def reply (workitem)

      # TODO: change method name (receiver mess cleanup)

      doc = fetch(Ruote::FlowExpressionId.extract_h(workitem))

      r = @context.storage.delete(doc)

      return reply(workitem) if r != nil

      workitem.h.delete('_rev')

      reply_to_engine(workitem)
    end

    # Returns the count of workitems stored in this participant.
    #
    def size

      fetch_all.size
    end

    # Iterates over the workitems stored in here.
    #
    def each (&block)

      all.each { |wi| block.call(wi) }
    end

    # Returns all the workitems stored in here.
    #
    def all

      fetch_all.map { |hwi| Ruote::Workitem.new(hwi) }
    end

    # A convenience method (especially when testing), returns the first
    # (only ?) workitem in the participant.
    #
    def first

      hwi = fetch_all.first

      hwi ? Ruote::Workitem.new(hwi) : nil
    end

    # Return all workitems for the specified wfid
    #
    def by_wfid (wfid)

      @context.storage.get_many('workitems', /!#{wfid}$/).map { |hwi|
        Ruote::Workitem.new(hwi)
      }
    end

    # Returns all workitems for the specified participant name
    #
    def by_participant (participant_name)

      hwis = if @context.storage.respond_to?(:by_participant)

        @context.storage.by_participant('workitems', participant_name)

      else

        fetch_all.select { |wi| wi['participant_name'] == participant_name }
      end

      hwis.collect { |hwi| Ruote::Workitem.new(hwi) }
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
    def by_field (field, value=nil)

      hwis = if @context.storage.respond_to?(:by_field)

        @context.storage.by_field('workitems', field, value)

      else

        fetch_all.select { |hwi|
          hwi['fields'].keys.include?(field) &&
          (value.nil? || hwi['fields'][field] == value)
        }
      end

      hwis.collect { |hwi| Ruote::Workitem.new(hwi) }
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
    # for pagination.
    #
    # Note : the criteria is AND only, you'll have to do ORs (aggregation)
    # by yourself.
    #
    def query (criteria)

      cr = criteria.inject({}) { |h, (k, v)| h[k.to_s] = v; h }

      return @context.storage.query_workitems(cr).collect { |h|
        Ruote::Workitem.new(h)
      } if @context.storage.respond_to?(:query_workitems)

      offset = cr.delete('offset')
      limit = cr.delete('limit')

      wfid = cr.delete('wfid')
      pname = cr.delete('participant_name') || cr.delete('participant')

      hwis = if wfid
        @context.storage.get_many('workitems', /!#{wfid}$/)
      else
        fetch_all
      end

      hwis = hwis.select { |hwi|
        Ruote::StorageParticipant.matches?(hwi, pname, cr)
      }.collect { |hwi|
        Ruote::Workitem.new(hwi)
      }

      offset = offset || 0
      limit = limit || hwis.length

      hwis[offset, limit]
    end

    # Cleans this participant out completely
    #
    def purge!

      fetch_all.each { |hwi| @context.storage.delete( hwi ) }
    end

    # Used by #query when filtering workitems.
    #
    def self.matches? (hwi, pname, criteria)

      return false if pname && hwi['participant_name'] != pname

      fields = hwi['fields']

      criteria.each do |fname, fvalue|
        return false if fields[fname] != fvalue
      end

      true
    end

    protected

    # Fetches all the workitems. If there is a @store_name, will only fetch
    # the workitems in that store.
    #
    def fetch_all

      key = @store_name ? /^wi!#{@store_name}::/ : nil

      @context.storage.get_many('workitems', key)
    end

    # Computes the id for the document representing the document in the storage.
    #
    def to_id (fei)

      a = [ Ruote.to_storage_id(fei) ]

      a.unshift(@store_name) if @store_name

      a.unshift('wi')

      a.join('!')
    end
  end
end

