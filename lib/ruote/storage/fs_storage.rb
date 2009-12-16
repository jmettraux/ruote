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

require 'rufus/cloche' # gem install rufus-cloche


module Ruote

  class FsStorage

    include StorageBase

    def initialize (dir, options={})

      FileUtils.mkdir_p(dir)

      @cloche = Rufus::Cloche.new(:dir => dir)
      @options = options

      @cloche.put(@options.merge('type' => 'configurations', '_id' => 'engine'))
    end

    def put (doc, opts={})

      @cloche.put(doc.merge!('put_at' => Ruote.now_to_utc_s))
    end

    def get (type, key)

      @cloche.get(type, key)
    end

    def delete (doc)

      @cloche.delete(doc)
    end

    def get_many (type, key=nil, opts={})

      @cloche.get_many(type, key, opts)
    end

    def purge!

      FileUtils.rm_rf(@cloche.dir)
    end

    def dump (type)

      s = "=== #{type} ===\n"

      @cloche.get_many(type).inject(s) do |s1, e|
        s1 << "\n"
        e.keys.sort.inject(s1) do |s2, k|
          s2 << "  #{k} => #{e[k].inspect}\n"
        end
      end
    end
  end
end

