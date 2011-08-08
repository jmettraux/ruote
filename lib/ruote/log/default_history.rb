#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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
  # NOTE : this default history is worthless when there are multiple workers.
  # It only keeps track of the 'local' worker if there is one present.
  #
  class DefaultHistory

    DATE_REGEX = /!(\d{4}-\d{2}-\d{2})!/
    DEFAULT_MAX_SIZE = 1000

    def initialize(context, options={})

      @context = context
      @options = options

      @history = []
    end

    # Returns all the msgs (events), most recent one is last.
    #
    def all

      @history
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

    # This method is called by the worker via the context. Succesfully
    # processed msgs are passed here.
    #
    def on_msg(msg)

      msg = Ruote.fulldup(msg)
      msg['seen_at'] = Ruote.now_to_utc_s

      @history << msg

      while (@history.size > (@options[:max_size] || DEFAULT_MAX_SIZE)) do
        @history.shift
      end
    end
  end
end

