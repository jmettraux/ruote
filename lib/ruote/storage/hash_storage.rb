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

require 'rufus/json'
require 'ruote/util/misc'
require 'ruote/storage/base'
require 'monitor'


module Ruote

  #
  # An in-memory storage.
  #
  # Useful for testing or for transient engines.
  #
  class HashStorage

    include StorageBase
    include MonitorMixin

    attr_reader :h

    def initialize(options={})

      super()
        # since were including MonitorMixin, this super() is necessary

      @options = options

      purge!
        # which initializes @h

      replace_engine_configuration(options)
    end

    def put(doc, opts={})

      synchronize do

        pre = get(doc['type'], doc['_id'])

        if pre && pre['_rev'] != doc['_rev']
          return pre
        end

        if pre.nil? && doc['_rev']
          return true
        end

        doc = if opts[:update_rev]
          doc.merge!('_rev' => pre ? pre['_rev'] : -1)
        else
          doc.merge('_rev' => doc['_rev'] || -1)
        end

        doc['put_at'] = Ruote.now_to_utc_s
        doc['_rev'] = doc['_rev'] + 1
        doc = Ruote.keys_to_s(doc)

        @h[doc['type']][doc['_id']] = Rufus::Json.dup(doc)

        nil
      end

    #rescue => e
    #  puts "=" * 80
    #  File.open('doc.json', 'wb') do |f|
    #    f.puts Rufus::Json.pretty_encode(doc)
    #  end
    #  raise e
    end

    def get(type, key)

      synchronize do
        Ruote.fulldup(@h[type][key])
      end
    end

    def delete(doc)

      drev = doc['_rev']

      raise ArgumentError.new("can't delete doc without _rev") unless drev

      synchronize do

        prev = get(doc['type'], doc['_id'])

        return true if prev.nil?

        doc['_rev'] ||= 0

        return prev if prev['_rev'] != drev

        @h[doc['type']].delete(doc['_id'])

        nil # success
      end
    end

    def get_many(type, key=nil, opts={})

      # NOTE : no dup here for now

      synchronize do

        docs = if key
          keys = Array(key).map { |k| k.is_a?(String) ? "!#{k}" : k }
          @h[type].values.select { |doc| key_match?(type, keys, doc) }
        else
          @h[type].values
        end

        return docs.size if opts[:count]

        docs = docs.sort_by { |d| d['_id'] }
        docs = docs.reverse if opts[:descending]

        skip = opts[:skip] || 0
        limit = opts[:limit] || docs.size

        docs[skip, limit]
      end
    end

    # Returns a sorted list of all the ids for a given type.
    #
    def ids(type)

      @h[type].keys.sort
    end

    #--
    # keeping it commented out... using it for documentation efforts
    #class NoisyHash < Hash
    #  def initialize(type)
    #    @type = type
    #    super()
    #  end
    #  def []=(k, v)
    #    puts "       + #{@type}.put #{k} #{v['_rev']}"
    #    super
    #  end
    #  def delete(k)
    #    puts "       - #{@type}.del #{k} "
    #    super
    #  end
    #end
    #++

    # Purges the storage completely.
    #
    def purge!

      @h = %w[

        variables

        msgs
        expressions
        errors
        schedules
        configurations
        workitems

      ].each_with_object({}) { |k, h|
        h[k] = {}
      }

      @h['configurations']['engine'] = @options
    end

    def add_type(type)

      @h[type] = {}
    end

    def purge_type!(type)

      @h[type] = {}
    end

    # Shuts this storage down.
    #
    def shutdown

      # nothing to do
    end
  end
end

