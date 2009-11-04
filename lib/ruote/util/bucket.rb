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

    def initialize (fpath, default_value=nil)

      @fpath = fpath

      @new_file = (not File.exist?(@fpath))
      FileUtils.touch(@fpath) if @new_file

      @file = File.open(@fpath, 'rb+')

      @raw = nil
      @data = nil
      @mtime = nil

      save(default_value) if @new_file && default_value != nil
    end

    # Returns true if the bucket had to create the file
    #
    def new_file?

      @new_file
    end

    # Closes this bucket (the File instance specifically).
    #
    def close

      @file.close
    end

    #--
    # LOAD and SAVE
    #++

    # Exclusive, blocking lock while reading. Doesn't read if the file
    # hasn't changed.
    #
    def load

      mt = @file.mtime rescue nil

      lock { read } if (not @mtime) or (not mt) or (mt > @mtime)

      @data
    end

    # Exclusive, blocking lock while writing. Doesn't save if the file
    # hasn't changed since last load or save.
    #
    def save (data)

      #p [ @fpath, :save, data ] if data == []
      #caller.each { |l| puts l } if data == []

      lock { write(data) }
    end

    #--
    # OPERATE
    #++

    # Expects a block. Data is read then fed to block. Data is saved once
    # the block is over. (no save if no changes).
    #
    # If skip is set to true, this method will exit immediately (block not
    # called) if the bucket is already locked.
    #
    def operate (skip, &block)

      lock(skip) do
        read
        r = block.call(@data)
        save(@data)
        r
      end
    end

    protected

    def lock (skip=false, &block)

      return if skip and locked?

      begin
        @file.flock(File::LOCK_EX)
        block.call
      ensure
        begin
          @file.flock(File::LOCK_UN)
        rescue Exception => e
          #p [ @fpath, :lock,  e ]
        end
      end
    end

    def read

      begin

        r = @raw

        @file.pos = 0
        @raw = @file.read

        @data = Marshal.load(@raw)

        @mtime = @file.mtime

      rescue Exception => e

        #puts "~~~ #{@fpath}"; p e
        #caller.each { |l| puts l }

        @raw, @data, @mtime = nil
      end
    end

    def write (data)

      raw = Marshal.dump(data)
        # beware of marshalling errors here

      return if raw == @raw # no changes

      @data = data
      @raw = raw

      #puts
      #puts `lsof | grep ruota.work | awk '{ print $9 }' | sort`
      #puts

      @file.pos = 0
      l = @file.syswrite(raw)
      @file.flush # very important
      @file.truncate(l)

      @mtime = @file.mtime
    end

    def locked?

      # flock returns false if File::LOCK_NB is specified and
      # the operation would otherwise have blocked
      #
      # flock returns 0 if the locking was successful

      (@file.flock(File::LOCK_EX | File::LOCK_NB) == false)
    end
  end
end

