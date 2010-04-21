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

require 'rufus/json'
require 'ruote/util/misc'
require 'ruote/storage/base'
require 'monitor'


module Ruote

  # An in-memory storage.
  #
  class HashStorage

    include StorageBase
    include MonitorMixin

    attr_reader :h

    def initialize (options={})

      super()
        # since were including MonitorMixin, this super() is necessary

      purge!

      put(options.merge('type' => 'configurations', '_id' => 'engine'))
    end

    def put (doc, opts={})

      i = @h.size

      synchronize do

        pre = get(doc['type'], doc['_id'])

        #if pre && ( ! opts[:update_rev]) && pre['_rev'] != doc['_rev']
        if pre && pre['_rev'] != doc['_rev']
          return pre
        end

        if pre.nil? && doc['_rev']
          return true
        end

        doc = if opts[:update_rev]
          doc['_rev'] = pre ? pre['_rev'] : -1
          doc
        else
          doc.merge('_rev' => doc['_rev'] || -1)
        end

        doc['put_at'] = Ruote.now_to_utc_s
        doc['_rev'] = doc['_rev'] + 1

        @h[doc['type']][doc['_id']] = Rufus::Json.dup(doc)

        nil
      end
    end

    def get (type, key)

      synchronize do
        Ruote.fulldup(@h[type][key])
      end
    end

    def delete (doc)

      drev = doc['_rev']

      raise ArgumentError.new("can't delete doc without _rev") unless drev

      synchronize do

        prev = get(doc['type'], doc['_id'])

        return true if prev.nil?

        doc['_rev'] ||= 0

        if prev['_rev'] == drev

          @h[doc['type']].delete(doc['_id'])

          nil

        else

          prev
        end
      end
    end

    def get_many (type, key=nil, opts={})

      # NOTE : no dup here for now

      synchronize do

        docs = key ?
          @h[type].values.select { |doc| doc['_id'].match(key) } :
          @h[type].values

        if l = opts[:limit]
          docs[0, l]
        else
          docs
        end
      end
    end

    # Returns a sorted list of all the ids for a given type.
    #
    def ids (type)

      @h[type].keys.sort
    end

    def purge!

      @h = %w[

        variables

        msgs
        expressions
        errors
        schedules
        configurations
        workitems

      ].inject({}) { |h, k|
        h[k] = {}
        h
      }

      @h['configurations']['engine'] = @options
    end

    def add_type (type)

      @h[type] = {}
    end

    def purge_type! (type)

      @h[type] = {}
    end

    def dump (type)

      s = "=== #{type} ===\n"

      @h[type].inject(s) do |s1, (k, v)|
        s1 << "\n"
        s1 << "#{k} :\n"
        v.keys.sort.inject(s1) do |s2, k1|
          s2 << "  #{k1} => #{v[k1].inspect}\n"
        end
      end
    end
  end
end

