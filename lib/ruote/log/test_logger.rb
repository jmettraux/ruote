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


require 'ruote/util/tree'
require 'ruote/log/logger'


module Ruote

  # Logs everything that occurs in the workqueue in an array.
  #
  # DO NOT use this in production. It's testing only.
  #
  class TestLogger < Logger

    attr_reader :log

    def initialize

      @log = []

      @index = 0
      @mutex = Mutex.new
      @queue = Queue.new

      @wait_patterns = nil
    end

    def wait_for (patterns)

      @mutex.synchronize do

        while evt = @log[@index]
          @index += 1
          return evt if pats_match?(evt, patterns)
        end

        @wait_patterns = patterns
      end
      @queue.shift
    end

    def to_stdout

      @log.each { |evt| output(evt.last, summarize(*evt)) }
    end

    protected

    def receive (*event)
      @mutex.synchronize do

        @log << event
        output(event.last, summarize(*event)) if context[:noisy]

        if @wait_patterns

          @index = @log.size

          if pats_match?(event, @wait_patterns)
            @wait_patterns = nil
            @queue.push(event)
          end
        end
      end
    end

    def pats_match? (event, patterns)

      patterns.find { |pat| pat_match?(event, pat) }
    end

    def pat_match? (event, pattern)

      pc, pm, pa = pattern
      ec, em, ea = event

      return false if pc && ec != pc
      return false if pm && em != pm

      pa.each do |k, v|
        next if k == :wfid && ea[:parent_wfid] == v
        return false if ea[k] != v
      end

      true
    end

    def output (eargs, data)

      fei = eargs[:fei]
      exp = eargs[:expression]
      wi = eargs[:workitem]

      fei = fei || (exp ? exp.fei : nil) || (wi ? wi.fei : nil)

      depth = fei ? fei.depth : 0

      c = data[0].to_s[0, 1]

      d1s = data[1].to_s

      m = d1s[0, 2]
      m = d1s if m == 'on' || m == 's_'
      m = d1s if %w[ entered_tag left_tag launch_sub ].include?(d1s)

      if m == 'ap' && eargs[:tree] && eargs[:fei].expid == '0'
        puts
        puts Ruote.tree_to_s(data[2][:tree])
        puts
      end

      puts "#{' ' * depth * 2}#{c} #{m} #{data[2].inspect}"
      #data[2].each do |k, v|
      #  puts "#{' ' * (depth * 2 + 4)}#{k}: #{v.inspect}"
      #end
    end
  end
end

