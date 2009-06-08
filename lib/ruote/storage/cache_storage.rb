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

require 'rufus/lru'

require 'ruote/engine/context'
require 'ruote/queue/subscriber'
require 'ruote/storage/base'


module Ruote

  class CacheStorage

    include EngineContext
    include StorageBase
    include Subscriber

    DEFAULT_SIZE = 5000

    def context= (c)

      @context = c

      size = @context[:expression_cache_size] || DEFAULT_SIZE
      size = DEFAULT_SIZE if size.to_s.to_i < 1

      @cache = LruHash.new(size)

      subscribe(:expressions)
    end

    def find_expressions (query={})

      exps = real_storage.find_expressions(query)
      exps.each { |fexp| @cache[fexp.fei] = fexp }

      exps
    end

    def [] (fei)

      if fexp = @cache[fei]

        return fexp
      end

      if fexp = real_storage[fei]

        @cache[fei] = fexp
        return fexp
      end

      nil # miss :(
    end

    def []= (fei, fexp)

      @cache[fei] = fexp
    end

    def delete (fei)

      @cache.delete(fei)
    end

    def size

      real_storage.size
    end

    def to_s

      @cache.inject('') do |s, (k, v)|
        s << "#{k.to_s} => #{v.class}\n"
      end
    end

    protected

    def real_storage

      @context[:s_expression_storage__1]
    end
  end
end

