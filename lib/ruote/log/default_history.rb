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


module Ruote

  #
  # A default history implementation, only keeps the most recent stuff
  # in memory.
  #
  # This class includes Enumerable.
  #
  # NOTE:
  #
  # This default history is worthless when there are multiple workers.
  # It only keeps track of the msgs processed by the worker in the same
  # context. Msgs processed by other workers (in different Ruby runtimes) are
  # not seen (they are tracked by the DefaultHistory next to those workers).
  #
  # By default, this history keeps track of the latest 1'000 msgs.
  # This can be changed by passing a 'history_max_size' option to the storage
  # when initializing ruote ('history_max_size' => 0) is acceptable.
  #
  class DefaultHistory

    include Enumerable

    DATE_REGEX = /!(\d{4}-\d{2}-\d{2})!/
    DEFAULT_MAX_SIZE = 1000

    def initialize(context, options={})

      @context = context
      @options = options

      @max_size = context['history_max_size'] || DEFAULT_MAX_SIZE

      @history = []
    end

    # Returns all the msgs (events), most recent one is last.
    #
    def all

      @history
    end

    # Enabling Enumerable...
    #
    def each(&block)

      @history.each(&block)
    end

    # Returns all the wfids for which some piece of history is kept.
    #
    def wfids

      @history.collect { |msg|
        msg['wfid'] || (msg['fei']['wfid'] rescue nil)
      }.compact.uniq.sort
    end

    # Returns all the msgs (events) for a given wfid. (Well, all the msgs
    # that are kept.
    #
    def by_process(wfid)

      @history.select { |msg|
        (msg['wfid'] || (msg['fei']['wfid'] rescue nil)) == wfid
      }
    end
    alias by_wfid by_process

    # Returns an array [ most recent date, oldest date ] (Time instances).
    #
    def range

      now = Time.now

      [ (Time.parse(@history.first['seen_at']) rescue now),
        (Time.parse(@history.last['seen_at']) rescue now) ]
    end

    def by_date(date)

      d = Time.parse(date.to_s).utc.strftime('%Y-%m-%d')

      @history.select { |m| Time.parse(m['seen_at']).strftime('%Y-%m-%d') == d }
    end

    #def history_to_tree (wfid)
    #  # (NOTE why not ?)
    #end

    # Forgets all the stored msgs.
    #
    def clear!

      @history.clear
    end

    # This method is called by the worker via the context. Successfully
    # processed msgs are passed here.
    #
    def on_msg(msg)

      return if @max_size < 1

      msg = Ruote.fulldup(msg)
      msg['seen_at'] = Ruote.now_to_utc_s

      @history << msg

      while (@history.size > @max_size) do
        @history.shift
      end

    rescue => e

      $stderr.puts '>' + '-' * 79
      $stderr.puts "#{self.class} issue, skipping"
      $stderr.puts e.inspect
      $stderr.puts e.backtrace[0, 2]
      $stderr.puts '<' + '-' * 79
    end
  end
end

