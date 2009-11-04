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


require 'thread'
require 'ruote/queue/workqueue'


module Ruote

  #
  # The simplest of the queue implementation for ruote.
  #
  # Relies on the Queue class provided by ruby.
  #
  class ThreadWorkqueue < Workqueue

    def initialize

      super()

      @queue = Queue.new

      @thread = Thread.new do
        loop { process(@queue.pop) }
      end

      @thread[:name] = "#{self.class} - #{Ruote::VERSION}"
    end

    # Emits event for later processing
    #
    def emit (eclass, emsg, eargs)

      @queue.push([ eclass, emsg, eargs ])
    end

    # Makes sure the queue is empty before shutdown is complete.
    #
    def shutdown

      while @queue.size > 0; Thread.pass; end

      Thread.kill(@thread)
    end

    # Basically, it returns when there are no more jobs... It's like #shutdown.
    #
    def purge!

      shutdown
    end
  end
end

