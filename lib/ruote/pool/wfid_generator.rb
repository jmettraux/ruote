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


require 'time'
require 'thread'
require 'fileutils'
require 'ruote/engine/context'


module Ruote

  #
  # A simple wfid generator. The pattern is "%Y%m%d%H%m%S-usec".
  #
  class WfidGenerator

    include EngineContext


    def context= (c)

      @context = c
      @mutex = Mutex.new
      @file = nil

      load_last
      save_last
    end

    # Generates a wfid (workflow instance id (process instance id))
    #
    def generate

      @mutex.synchronize do

        wfid = Time.now
        wfid = @last + 0.001 if wfid <= @last

        @last = wfid
        save_last

        #line = caller[4]
        #if line.match(/\/functional\//)
        #  p "#{@last.strftime('%Y%m%d%H%m%S')}-#{@last.usec}"
        #  puts caller[4]
        #end

        "#{@last.strftime('%Y%m%d%H%M%S')}-#{@last.usec}"
      end
    end

    # Simply hands back the wfid string (this method is used by FsStorage
    # to determine in which dir expression should be stored).
    #
    def split (wfid)

      (0..wfid.length - 1).collect { |i| wfid[i, 1] } # 1.8 and 1.9
    end

    def shutdown

      @file.close
    end

    protected

    def file_path

      File.join(workdir, 'wfidgen.last')
    end

    def load_last

      t = File.read(file_path).strip rescue ''
      t = Time.parse(t)
      n = Time.now
      @last = t > n ? t : n
    end

    def save_last

      @file = File.open(file_path, 'w+') if (not @file) or @file.closed?
      @file.pos = 0
      l = @file.syswrite("#{@last.strftime('%Y/%m/%d %H:%m:%S')}.#{@last.usec}")
      @file.truncate(l)
    end
  end
end
