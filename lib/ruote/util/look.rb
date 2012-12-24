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
  # Some methods for looking at system/runtime things.
  #
  module Look

    def self.lsof

      `lsof -p #{$$}`
    end

    def self.dump_lsof

      result = lsof

      puts '= lsof =' + '=' * 71
      puts result
      puts result.split("\n").size
      puts '=' * 80
    end

    def self.dump_lsof_count

      puts '= lsof count =' + '=' * 65
      puts lsof.split("\n").size
      puts '=' * 80
    end
  end

  #
  # Some utilities for mem usage analysis
  #
  module Mem

    # Returns a Hash : classname => [ count, maxsize, totalsize, avgsize ]
    #
    # The relative size of an object is computed with Marshal.dump(o).size
    #
    # This uses ObjectSpace.
    #
    # see http://www.ruby-forum.com/topic/186339 for better options.
    #
    def self.count

      uninteresting = [
        Array, String, Hash, Set, Module, Range, Float, Bignum
      ]

      h = {}

      ObjectSpace.each_object do |o|

        next if uninteresting.include?(o.class)

        stats = h[o.class.to_s] ||= [ 0, 0, 0 ]
        size = (Marshal.dump(o).size rescue 1)

        stats[0] += 1
        stats[1] = size if size > stats[1]
        stats[2] += size
      end

      a = h.to_a
      a.each { |k, v| v << v[2] / v[0] }

      a.sort { |x, y| x.last[1] <=> y.last[1] }.reverse
    end

    # Very naive : does a "ps aux | grep pid".
    #
    # Returns a hash like this one :
    #
    #   {
    #     :user => "jmettraux",
    #     :pid => "1100",
    #     :cpu => "73.0",
    #     :mem => "0.8",
    #     :vsz => "2472732",
    #     :rss => "35308",
    #     :tt => "s001",
    #     :stat => "S+",
    #     :started => "8:55PM",
    #     :time => "0:01.05",
    #     :command => "ruby start.rb"
    #   }
    #
    def self.ps

      s = `ps aux | egrep '^.+ +#{$$} '`.split(' ')
      s[10] = s[10..-1].join(' ') # the command

      h = {}

      %w[
        user pid cpu mem vsz rss tt stat started time command
      ].each_with_index { |k, i| h[k.to_sym] = s[i] }

      h
    end
  end
end

