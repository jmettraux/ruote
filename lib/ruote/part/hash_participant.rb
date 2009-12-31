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
  # Storing workitems in-memory. Mainly used for testing purposes, but could
  # prove useful for a transient ruote engine.
  #
  class HashParticipant

    include LocalParticipant
    include Enumerable

    def initialize (opts=nil)

      @items = {}
    end

    # No need for a separate thread when delivering to this participant.
    #
    def do_not_thread; true; end

    def consume (workitem)

      @items[workitem.fei.to_storage_id] = workitem
    end

    # Makes sure to remove the workitem from the in-memory hash.
    #
    def cancel (fei, flavour)

      @items.delete(fei.to_storage_id)
    end

    # Removes the workitem from the in-memory hash and replies to the engine.
    #
    def reply (workitem)

      @items.delete(workitem.fei.to_storage_id)
      reply_to_engine(workitem)
    end

    # Returns the count of workitems stored in this participant.
    #
    def size

      @items.size
    end

    # Iterates over the workitems stored in here.
    #
    def each (&block)

      @items.each { |i| block.call(i) }
    end

    # A convenience method (especially when testing), returns the first
    # (only ?) workitem in the participant.
    #
    def first

      @items.values.first
    end
  end
end

