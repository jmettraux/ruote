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

require 'parslet'


module Ruote

  #
  # Turning radial strings into ruote trees.
  #
  module RadialReader

    #
    # Turns radial strings into intermediate trees.
    #
    class Parser < Parslet::Parser

      rule(:spaces) {
        match('\s').repeat >>
        (str('#') >> match('[^\n]').repeat >> str("\n").present?).maybe >>
        match('\s').repeat
      }
      rule(:spaces?) { spaces.maybe }

      rule(:comma) { spaces? >> str(',') >> spaces? }
      rule(:digit) { match('[0-9]') }

      rule(:text) { match('[^\s:,=\[\]#]').repeat(1).as(:text) }

      rule(:number) {
        (
          str('-').maybe >> (
            str('0') | (match('[1-9]') >> digit.repeat)
          ) >> (
            str('.') >> digit.repeat(1)
          ).maybe >> (
            match('[eE]') >> (str('+') | str('-')).maybe >> digit.repeat(1)
          ).maybe
        ).as(:number) >> match('[ \n,]').present?
      }

      rule(:string) {
        str('"') >> (
          str('\\') >> any | match('[^"]')
        ).repeat.as(:string) >> str('"') |
        str("'") >> (
          str('\\') >> any | match("[^']")
        ).repeat.as(:string) >> str("'")
      }

      rule(:regex) {
        str('/') >> (
          str('\\') >> any | match("[^\/]")
        ).repeat.as(:regex) >> str('/')
      }

      rule(:array) {
        str('[') >> spaces? >>
        (value >> (comma >> value).repeat).maybe.as(:array) >>
        spaces? >> str(']')
      }

      rule(:object) {
        str('{') >> spaces? >>
        (entry >> (comma >> entry).repeat).maybe.as(:object) >>
        spaces? >> str('}')
      }

      rule(:null) {
        (str('null') | str('nil')).as(:null)
      }

      rule(:value) {
        array | object |
        string | number |
        str('true').as(:true) | str('false').as(:false) |
        null | regex | text
      }

      rule(:entry) {
        ((string | null | regex | text).as(:key) >> spaces? >>
         (str(':') | str('=>')) >> spaces? >>
         value.as(:val)).as(:ent)
      }

      rule(:attribute) { (entry | value).as(:att) }

      rule(:blanks) { match('[ \t]').repeat(1) }

      rule(:blank_line) { blanks.maybe }
      rule(:line) {
        (
          str(' ').repeat.as(:ind) >>
          match('[^ \n#"\',]').repeat(1).as(:exp) >>
          (
            (comma | blanks) >> attribute >> (comma >> attribute).repeat
          ).as(:atts).maybe
        ).as(:line)
      }

      rule(:comment) {
        str(' ').repeat >>
        (str('#') >> match('[^\n]').repeat).maybe >>
        str("\n").present?
      }

      rule(:lines) {
        (str("\n") >> (line | blank_line) >> comment.maybe).repeat
      }

      root(:lines)
    end

    #
    # A helper class to store the temporary tree while it gets read.
    #
    class Node

      attr_reader :parent, :indentation, :children

      def initialize(indentation, expname, attributes)

        @parent = nil
        @indentation = indentation
        @children = []

        @expname = expname#.gsub(/-/, '_')
        @expname.gsub!(/-/, '_') if @expname.match(/^[a-z\-]+$/)
        @attributes = attributes
      end

      def parent=(node)

        @parent = node
        @parent.children << self
      end

      def to_a

        [ @expname, @attributes, @children.collect { |c| c.to_a } ]
      end
    end

    #
    # Turns intermediate trees into ruote trees.
    #
    class Transformer < Parslet::Transform

      class Attribute
        attr_reader :key, :val
        def initialize(key, val)
          @key = key.to_s.gsub(/-/, '_')
          @val = val
        end
      end
      class Value < Attribute
        def initialize(key)
          @key = key
          @val = nil
        end
      end

      rule(:line => subtree(:line)) { line }

      rule(:ind => simple(:i), :exp => simple(:e), :atts => subtree(:as)) {
        atts = Array(as).each_with_object({}) { |att, h| h[att.key] = att.val }
        Node.new(i.to_s.length, e.to_s, atts)
      }
      rule(:ind => simple(:i), :exp => simple(:e)) {
        Node.new(i.to_s.length, e.to_s, {})
      }
      rule(:ind => sequence(:i), :exp => simple(:e), :atts => subtree(:as)) {
        atts = Array(as).each_with_object({}) { |att, h| h[att.key] = att.val }
        Node.new(0, e.to_s, atts)
      }
      rule(:ind => sequence(:i), :exp => simple(:e)) {
        Node.new(0, e.to_s, {})
      }

      rule(:att => { :ent => { :key => subtree(:k), :val => subtree(:v) } }) {
        Attribute.new(k, v)
      }
      rule(:att => subtree(:t)) {
        Value.new(t)
      }

      rule(:string => simple(:st)) {
        st.to_s.gsub(/\\(.)/) { eval("\"\\" + $~[1] + '"') }
      }
      rule(:regex => simple(:re)) {
        '/' + re.to_s.gsub(/\\(.)/) { eval("\"\\" + $~[1] + '"') } + '/'
      }

      rule(:text => simple(:te)) { te.to_s }
      rule(:number => simple(:n)) { n.match(/[eE\.]/) ? Float(n) : Integer(n) }
      rule(:false => simple(:b)) { false }
      rule(:true => simple(:b)) { true }
      rule(:null => simple(:n)) { nil }

      rule(:array => subtree(:ar)) {
        ar.is_a?(Array) ? ar : [ ar ]
      }
      rule(:object => subtree(:es)) {
        (es.is_a?(Array) ? es : [ es ]).each_with_object({}) { |e, h|
          e = e[:ent]; h[e[:key]] = e[:val]
        }
      }
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

    # Returns tree if s seems to contain a radial process definition
    #
    def self.understands?(s)

      return false if s.match(/\n *end\b/)
      return false if s.match(/\bRuote\.(process_definition|workflow_definition|define)\b/)
      true
    end

    # The entry point : takes a radial string and returns, if possible,
    # a ruote tree.
    #
    def self.read(s, opt=nil)

      parser = Parser.new
      transformer = Transformer.new

      lines = parser.parse("\n#{s}\n")
      nodes = transformer.apply(lines)

      root = PreRoot.new("#{s.strip.split("\n").first}...")
      current = root

      nodes = [] unless nodes.is_a?(Array)
        # force ArgumentError via empty PreRoot

      nodes.each do |node|

        parent = current

        if node.indentation == current.indentation
          parent = current.parent
        elsif node.indentation < current.indentation
          while node.indentation <= parent.indentation
            parent = parent.parent
          end
        end

        node.parent = parent
        current = node
      end

      root.to_a
    end
  end
end

