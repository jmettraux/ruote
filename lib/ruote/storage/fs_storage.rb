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


require 'rufus-json/automatic'
require 'rufus-cloche'

require 'ruote/storage/base'


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
    def initialize(dir, options={})

      if dir.is_a?(Hash) && options == {}
        options = dir
        dir = options.delete('dir')
      end

      FileUtils.mkdir_p(dir)

      @cloche = Rufus::Cloche.new(
        :dir => dir, :nolock => options['cloche_nolock'])

      replace_engine_configuration(options)
    end

    def dir

      @cloche.dir
    end

    def put(doc, opts={})

      doc = doc.send(
        opts[:update_rev] ? 'merge!' : 'merge',
        'put_at' => Ruote.now_to_utc_s)

      @cloche.put(doc, opts)
    end

    def get(type, key)

      @cloche.get(type, key)
    end

    def delete(doc)

      @cloche.delete(doc)
    end

    def get_many(type, key=nil, opts={})

      keys = key ? Array(key) : nil

      keys = keys.map { |k|
        type == 'schedules' ? /!#{k}-\d+$/ : "!#{k}"
      } if keys && keys.first.is_a?(String)

      @cloche.get_many(type, keys, opts)
    end

    def ids(type)

      @cloche.ids(type)
    end

    # Purges the storage completely.
    #
    def purge!

      FileUtils.rm_rf(@cloche.dir)
    end

    # No need for that here (FsStorage can add types on the fly).
    #
    def add_type(type)
    end

    def purge_type!(type)

      @cloche.purge_type!(type)
    end

    # Shuts this storage down.
    #
    def shutdown

      # nothing to do
    end
  end
end

