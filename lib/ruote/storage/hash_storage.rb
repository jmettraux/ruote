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


module Ruote

  class HashStorage

    def initialize (options={})

      @options = options

      purge!
    end

    def put (doc)
      (@hash[doc['type']] ||= {})[doc['_id']] = doc
      nil
    end

    def get (type, key)
      @hash[type][key]
    end

    def delete (doc)
      @hash[doc['type']].delete(doc['_id'])
      nil
    end

    def get_many (type, key=nil)

      (key ?
        @hash[type].values.select { |doc| doc['_id'].match(key) } :
        @hash[type].values
      ).sort { |d0, d1|
        d0['_id'] <=> d1['_id']
      }
    end

    def purge!

      @hash = %w[
        tasks
        expressions
        errors
        ats
        crons
        configuration
        misc
      ].inject({}) { |h, k|
        h[k] = {}
        h
      }
    end
  end
end

