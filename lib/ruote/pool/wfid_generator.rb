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
require 'rufus/mnemo' # sudo gem install rufus-mnemo
require 'ruote/engine/context'


module Ruote

  class WfidGenerator

    include EngineContext


    def context= (c)

      @context = c

      @mutex = Mutex.new

      load_last
      save_last
    end

    def generate

      @mutex.synchronize do
        wfid = Time.now
        wfid = @last + 0.001 if wfid <= @last
        @last = wfid
        save_last
        "#{@last.strftime('%Y%m%d%H%m%S')}-#{@last.usec}"
      end
    end

    protected

    def file_path

      File.join(workdir, 'wfidgen.last')
    end

    def load_last

      FileUtils.mkdir(workdir) unless File.exist?(workdir)
      t = File.read(file_path).strip rescue ''
      t = Time.parse(t)
      n = Time.now
      @last = t > n ? t : n
    end

    def save_last

      @file = File.open(file_path, 'w+') if (not @file) or @file.closed?
      @file.pos = 0
      @file.puts("#{@last.strftime('%Y/%m/%d %H:%m:%S')}.#{@last.usec}")
    end
  end
end
