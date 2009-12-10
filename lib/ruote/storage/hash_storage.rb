#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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
require 'monitor'


module Ruote

  class HashStorage

    include StorageBase
    include MonitorMixin

    attr_reader :h

    def initialize (options={})

      super()

      @options = options

      purge!
    end

    def put (doc)

      synchronize do

        prev = get(doc['type'], doc['_id'])

        if prev.nil? || prev['_rev'] == (doc['_rev'] || 0)

          (@h[doc['type']] ||= {})[doc['_id']] =
            Ruote::fulldup(doc).merge!(
              'put_at' => Ruote.now_to_utc_s,
              '_rev' => (doc['_rev'] || -1) + 1)

          nil

        else

          prev
        end
      end
    end

    def get (type, key)

      synchronize do
        Ruote::fulldup(@h[type][key])
      end
    end

    def delete (doc)

      synchronize do

        prev = get(doc['type'], doc['_id'])

        return true if prev.nil?

        doc['_rev'] ||= 0

        if prev['_rev'] == doc['_rev']

          @h[doc['type']].delete(doc['_id'])

          nil

        else

          prev
        end
      end
    end

    def get_many (type, key=nil)

      # NOTE : no dup here for now

      synchronize do
        key ?
          @h[type].values.select { |doc| doc['_id'].match(key) } :
          @h[type].values
      end
    end

    def purge!

      @h = %w[

        last_wfid
        trackers

        msgs
        expressions
        errors
        ats
        crons
        configurations
        workitems

      ].inject({}) { |h, k|
        h[k] = {}
        h
      }

      @h['configurations']['engine'] = @options
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

