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

require 'digest/md5'
require 'rufus/mnemo'


module Ruote

  #
  # The default wfid generator.
  #
  class MnemoWfidGenerator

    def initialize(context)

      @context = context

      @here = "#{Ruote.local_ip}!#{Process.pid}"
      @counter = 0
      #@mutex = Mutex.new
    end

    def generate

      t = Time.now.utc
      time = t.strftime('%Y%m%d-%H%M')
      ms = t.to_f % 60.0

      #c = @mutex.synchronize { @counter = (@counter + 1) % 100_000 }
      @counter = (@counter + 1) % 100_000
        #
        # no need to worry about skipping a beat, no mutex.

      s = "#{ms}!#{Thread.current.object_id}!#{@here}!#{@counter}"
      s = Digest::MD5.hexdigest(s)

      x = Rufus::Mnemo.from_i(s[0, 6].to_i(16))
      y = Rufus::Mnemo.from_i(s[6, 6].to_i(16))

      "#{time}-#{x}-#{y}"
    end
  end
end

