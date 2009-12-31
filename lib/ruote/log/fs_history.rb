#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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

require 'fileutils'
require 'rufus/json'


module Ruote

  #
  # Logs the ruote engine history to files.
  #
  # REMEMBER : this FsHistory only logs 1 worker. StorageHistory is better
  # to let all the workers output history in the shared storage.
  #
  class FsHistory

    def initialize (context, options={})

      @context = context
      @options = options

      @path =
        @options['history_path'] ||
        @context['history_path'] ||
        File.join('work', 'log')

      FileUtils.mkdir_p(@path)

      @last = nil
      @file = nil

      if @context.respond_to?(:worker)
        @context.worker.subscribe(:all, self)
      end

      rotate_if_necessary
    end

    # Makes sure to close the history file.
    #
    def shutdown

      @file.close rescue nil
    end

    # Returns an array of Ruote::Record instances, each record represents
    # a ruote engine [history] event.
    # Returns an empty array if no history was found for the given wfid.
    #
    def by_process (wfid)

      files = Dir[File.join(@path, '*.json')].sort.reverse

      history = []

      files.each do |f|

        lines = File.readlines(f).reverse

        lines.each do |l|

          a = Rufus::Json.decode(l) rescue nil

          next unless a

          at, msg = a

          m_wfid = msg['wfid'] || (msg['fei']['wfid'] rescue nil)

          next if m_wfid != wfid

          history.unshift(a)

          return history if msg['action'] == 'launch'
        end
      end

      history # shouldn't occur, unless history [file] got lost
    end

    RANGE_REGEXP = /_([0-9]{4}-[0-9]{2}-[0-9]{2}).json$/

    # Returns an array [ most recent date, oldest date ] (Time instances).
    #
    def range

      files = Dir[File.join(@path, '*.json')].sort

      [ files.last, files.first ].inject([]) do |a, fn|
        if m = RANGE_REGEXP.match(fn)
          a << Time.parse(m[1])
        end
        a
      end
    end

    # Returns an array of Record instances for a given date, and any process
    # instance.
    #
    def by_date (date)

      date = Time.parse(date.to_s).strftime('%F')

      lines = File.readlines(File.join(@path, "history_#{date}.json")) rescue []

      lines.inject([]) do |a, l|
        if r = (Rufus::Json.decode(l) rescue nil)
          a << r
        end
        a
      end
    end

    #def history_to_tree (wfid)
    #  # (NOTE why not ?)
    #end

    # The history system doesn't implement purge! so that when purge! is called
    # on the engine, the history is not cleared.
    #
    # Call this *dangerous* clear! method to clean out any history file.
    #
    def clear!

      Dir[File.join(@path, "#{engine.engine_id}_*.txt")].each do |f|
        FileUtils.rm_f(f) rescue nil
      end
    end

    # This is the method called by the workqueue. Incoming engine events
    # are 'processed' here.
    #
    def notify (msg)

      rotate_if_necessary

      @file.puts(Rufus::Json.encode(
        [ "#{@last.strftime('%F %T')}.#{"%06d" % @last.usec}", msg ]))
      @file.flush
    end

    protected

    def rotate_if_necessary

      prev = @last
      @last = Time.now.utc

      return if prev && prev.day == @last.day

      @file.close rescue nil

      fn = [ 'history', @last.strftime('%F') ].join('_') + '.json'

      @file = File.open(File.join(@path, fn), 'a')
    end
  end
end

