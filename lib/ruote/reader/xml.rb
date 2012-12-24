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

require 'rexml/parsers/sax2parser'
require 'rexml/sax2listener'


module Ruote

  #
  # Turns an XML string into a process definition tree.
  #
  module XmlReader

    # Returns true if the string seems to be an XML string.
    #
    def self.understands?(s)

      !! s.strip.match(/<.+>/)
    end

    #
    # A helper class to store the temporary tree while it gets read.
    #
    class Node

      attr_reader :parent, :attributes, :children

      def initialize(parent, name, atts)

        @parent = parent
        @name = name
        @attributes = atts.remap { |(k, v), h| h[k.gsub(/-/, '_')] = v }
        @children = []

        parent.children << self if parent
      end

      def to_a

        [ @name, @attributes, @children.collect { |c| c.to_a } ]
      end
    end

    # Parses the XML string into a process definition tree (array of arrays).
    #
    def self.read(s, opt=nil)

      parser = REXML::Parsers::SAX2Parser.new(s)

      root = nil
      current = nil

      # u, l, q, a <=> url, local, qname, attributes

      parser.listen(:start_element) do |u, l, q, a|
        current = Node.new(current, l.gsub(/-/, '_'), a)
        root ||= current
      end
      parser.listen(:end_element) do |u, l, q, a|
        current = current.parent
      end

      parser.listen(:characters) do |text|
        t = text.strip
        current.attributes[t] = nil if t.size > 0
      end

      parser.parse

      root.to_a
    end
  end
end

