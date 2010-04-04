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

begin
  require 'yajl'
rescue LoadError
  require 'json'
end
  # gem install yajl-ruby OR json OR json_pure OR json-jruby

require 'rufus/json'
Rufus::Json.detect_backend

require 'rufus/cloche'
  # gem install rufus-cloche


module Ruote

  #
  # A basic FS-bound ruote storage. Leverages rufus-cloche
  # (http://github.com/jmettraux/rufus-cloche).
  #
  # Warning : for JRuby 1.4.0 on Ubuntu, passing the cloche_nolock option set
  # to true seems necessary.
  # See http://groups.google.com/group/openwferu-users/t/d82516ed3bdd8f23
  #
  class FsStorage

    include StorageBase

    # Creates a FsStorage pointing to the given dir.
    #
    # The options are classical engine configuration, but the 'cloche_nolock'
    # option is read by the storage and followed.
    #
    def initialize (dir, options={})

      FileUtils.mkdir_p(dir)

      @cloche = Rufus::Cloche.new(
        :dir => dir, :nolock => options['cloche_nolock'])

      @options = options

      @cloche.put(@options.merge('type' => 'configurations', '_id' => 'engine'))
    end

    def put (doc, opts={})

      @cloche.put(doc.merge!('put_at' => Ruote.now_to_utc_s), opts)
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

    def ids (type)

      @cloche.ids(type)
    end

    def purge!

      FileUtils.rm_rf(@cloche.dir)
    end

    # No need for that here (FsStorage adds type on the fly).
    #
    def add_type (type)
    end

    def purge_type! (type)

      @cloche.purge_type!(type)
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

