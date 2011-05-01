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
  # Turns a radial string into a ruote tree.
  #
  module RadialReader

    #
    # A helper class to store the temporary tree while it gets read.
    #
    class Node

      attr_reader :parent, :indentation, :children

      def initialize(parent, indentation, line)

        @parent = parent
        @indentation = indentation
        @children = []

        m = line.match(/^([a-z0-9_-]+)(?: +(.+))?$/)

        @name = m[1].gsub(/-/, '_')
        @attributes = parse_attributes(m[2])

        parent.children << self if parent
      end

      def to_a

        [ @name, @attributes, @children.collect { |c| c.to_a } ]
      end

      protected

      def parse_attributes(s)

        result = {}

        loop do

          key, s = find_json_value(s)
          return result if key == nil
          #p [ :key, key, s ]

          value, s = find_json_value(s)
          #p [ :value, value, s ]

          key = key.gsub(/-/, '_') if value != nil

          result[key] = value
        end
      end

      def find_json_value(original, length=nil)

        if length == nil

          return nil if original == nil or original.length < 1
          return nil if original.match(/^#/)

          length = original.length
        end

        if length < 1

          if m = original.match(/^([^"',:#]+)([,:#].+)?$/)
            return [ m[1].strip, lchomp(m[2]) ]
          end

          raise ArgumentError.new("couldn't find a JSON value in >#{original}<")
        end

        s = original[0, length]

        #(return [
        #  Rufus::Json.decode(s), lchomp(original[length..-1])
        #]) rescue nil
          #
          #
        val = Rufus::Json.decode(s) rescue nil
        if val != nil or s == 'nil'
          return [ val, lchomp(original[length..-1]) ]
        end
          #
          # counter-weight to annoying issue with yajl-ruby 0.8.2
          # I can't seem to reproduce it cold...

        find_json_value(original, length - 1)
      end

      def lchomp(s)

        if s and m = s.match(/^[,:] *(.+)$/)
          m[1]
        else
          s
        end
      end
    end

    #
    # Some kind of "root container", to avoid having to deal with nils
    # and making the parsing code more complicated (hopefully).
    #
    class PreRoot < Node

      def initialize(first_line)

        @first_line = first_line

        @parent = nil
        @indentation = -1
        @children = []
      end

      def to_a

        raise ArgumentError.new(
          "couldn't parse process definition out of >#{@first_line}<"
        ) unless @children.first

        @children.first.to_a
      end
    end

    def self.read(s)

      root = PreRoot.new(s.strip.split("\n").first)
      current = root

      s.each_line do |line|

        line = line.rstrip

        # discard empty lines and comments

        next if line.length < 1
        next if line.match(/^ *#/)

        # OK, we found a node, determine its parent

        ind = indentation(line)

        if ind > current.indentation
          parent = current
        elsif ind == current.indentation
          parent = current.parent
        else # ind < current.indentation
          parent = current
          while ind < current.indentation
            parent = parent.parent
          end
        end

        # then create it

        current = Node.new(parent, ind, line.lstrip)
      end

      root.to_a
    end

    # Returns the count of white spaces on the left of the given string.
    #
    def self.indentation(s)

      i = 0
      while m = s.match(/^ (.*)$/)
        i, s = i + 1, m[1]
      end

      i
    end
  end
end

