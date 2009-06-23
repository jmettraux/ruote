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

  #
  # A 'bucket' is a kind of cache file. It may be shared by multiple processes,
  # it reloads only if necessary.
  #
  class Bucket

    # TODO : flock management, polling :(

    def initialize (fname, default_class)

      @fname = fname
      @data = nil
      @mtime = nil
      @default_class = default_class
    end

    def load

      mt = mtime

      if (not @mtime) or (not mt) or (mt > @mtime)

        @data = File.open(@fname, 'rb') { |f|
          Marshal.load(f.read)
        } rescue @default_class.new

        @mtime = mtime
      end

      @data
    end

    def save (data)

      File.open(@fname, 'wb') { |f| f.write(Marshal.dump(data)) }
      @data = data
      @mtime = mtime
    end

    protected

    def mtime

      File.new(@fname).mtime rescue nil
    end
  end
end

