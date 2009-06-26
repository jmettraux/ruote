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

  class Bucket

    def initialize (fpath)

      @fpath = fpath
    end

    #--
    # LOAD and SAVE
    #++

    # Exclusive, blocking lock while reading. Doesn't read if the file
    # hasn't changed.
    #
    def load

      mt = file.mtime rescue nil

      lock { read } if (not @mtime) or (not mt) or (mt > @mtime)

      @data
    end

    # Exclusive, blocking lock while writing. Doesn't save if the file
    # hasn't changed since last load or save.
    #
    def save (data)

      lock { write(data) }
    end

    #--
    # OPERATE
    #++

    # Expects a block. Data is read then fed to block. Data is saved once
    # the block is over. (no save if no changes).
    #
    # If the bucket is already locked, will simply skip (this method is
    # intended for fs_scheduler.rb
    #
    def operate (&block)

      lock(true) do
        read
        block.call(@data)
        save(@data)
      end
    end

    protected

    def lock (skip=false, &block)

      return if skip and locked?

      begin
        file.flock(File::LOCK_EX)
        block.call
      ensure
        file.flock(File::LOCK_UN)
      end
    end

    def read

      begin
        @raw = File.open(@fpath, 'rb') { |f| f.read }
        @data = Marshal.load(@raw)
        @mtime = file.mtime
      rescue Exception => e
        @raw, @data, @mtime = nil
      end
    end

    def write (data)

      raw = Marshal.dump(data)

      return if raw == @raw # no changes

      @data = data
      @raw = raw

      File.open(@fpath, 'wb') { |f| f.write(@raw) }

      @mtime = file.mtime
    end

    def file

      return @file if @file
      FileUtils.touch(@fpath) unless File.exist?(@fpath)

      @file = File.new(@fpath)
    end

    def locked?

      (file.flock(File::LOCK_EX | File::LOCK_NB) == false)
    end
  end
end

