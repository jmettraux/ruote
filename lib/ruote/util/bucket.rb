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

    def initialize (fname, default_class, skip_when_locked=false)

      @fname = fname
      @file = nil

      @data = nil
      @mtime = nil
      @default_class = default_class
      @skip = skip_when_locked
    end

    def load

      mt = mtime

      if (not @mtime) or (not mt) or (mt > @mtime)

        return nil if @skip and locked?

        file.flock(File::LOCK_EX) # exclusive !

        @data = File.open(@fname, 'rb') { |f|
          Marshal.load(f.read)
        } rescue @default_class.new

        @mtime = mtime
      end

      return @data

    ensure
      file.flock(File::LOCK_UN)
    end

    def save (data)

      file.flock(File::LOCK_EX)

      File.open(@fname, 'wb') { |f| f.write(Marshal.dump(data)) }
      @data = data
      @mtime = mtime

    ensure
      file.flock(File::LOCK_UN)
    end

    protected

    def mtime

      file.mtime rescue nil
    end

    def file

      return @file if @file
      FileUtils.touch(@fname) unless File.exist?(@fname)

      @file = File.new(@fname)
    end

    def locked?

      (file.flock(File::LOCK_EX | File::LOCK_NB) == false)
    end
  end
end

