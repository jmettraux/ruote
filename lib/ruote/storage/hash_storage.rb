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


module Ruote

  class HashStorage

    include StorageBase

    attr_reader :h

    def initialize (options={})

      @options = options

      purge!
    end

    def put (doc)

      (@h[doc['type']] ||= {})[doc['_id']] =
        Ruote::fulldup(doc).merge!('put_at' => Time.now.utc.to_s)

      nil
    end

    def get (type, key)
      @h[type][key]
    end

    def delete (doc)
      @h[doc['type']].delete(doc['_id'])
      nil
    end

    def get_many (type, key=nil)

      key ?
        @h[type].values.select { |doc| doc['_id'].match(key) } :
        @h[type].values
    end

    def purge!

      @h = %w[
        tasks
        expressions
        errors
        ats
        crons
        configuration
        misc
        participants
      ].inject({}) { |h, k|
        h[k] = {}
        h
      }

      @h['configuration']['engine'] = @options
    end

    def dump (type)

      puts "=== #{type} ==="
      @h[type].each do |k, v|
        puts "      #{k} =>"
        p v
      end
    end
  end
end

