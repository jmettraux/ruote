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

  class StorageParticipant

    include LocalParticipant
    include Enumerable

    attr_accessor :context

    def initialize (options={})

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

    # Makes sure to remove the workitem from the in-memory hash.
    #
    def cancel (fei, flavour)

      doc = fetch(fei)

      r = @storage.delete(doc)

      cancel(fei, flavour) if r != nil
    end

    def [] (fei)

      doc = fetch(fei)

      doc ? Ruote::WorkItem.new(doc) : nil
    end

    def fetch (fei)

      @context.storage.get('workitems', to_id(fei))
    end

    # Removes the workitem from the in-memory hash and replies to the engine.
    #
    def reply (workitem)

      doc = fetch(workitem.fei.to_h)

      r = @context.storage.delete(doc)

      return reply(workitem) if r != nil

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

      fetch_all.map { |hwi| block.call(Ruote::Workitem.new(hwi)) }
    end

    # A convenience method (especially when testing), returns the first
    # (only ?) workitem in the participant.
    #
    def first

      hwi = fetch_all.first

      hwi ? Ruote::Workitem.new(hwi) : nil
    end

    # Clean this participant out completely
    #
    def purge!

      fetch_all.each { |hwi| @context.storage.delete( hwi ) }
    end

    protected

    def fetch_all

      key = @store_name ? /^wi\_#{@store_name}::/ : nil

      @context.storage.get_many('workitems', key)
    end

    def to_id (fei)

      sid = Ruote.to_storage_id(fei)

      sid = @store_name ? "#{store_name}::#{sid}" : sid

      "wi_#{sid}"
    end
  end
end

