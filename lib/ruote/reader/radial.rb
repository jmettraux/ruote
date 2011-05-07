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

require 'parslet'


module Ruote

  #
  # Turns a radial string into a ruote tree.
  #
  module RadialReader

    class Parser < Parslet::Parser

      #rule(:spaces) { match('\s').repeat(1) }
      rule(:spaces) {
        match('\s').repeat >>
        (str('#') >> match('[^\n]').repeat >> str("\n").present?).maybe >>
        match('\s').repeat
      }
      rule(:spaces?) { spaces.maybe }

      rule(:comma) { spaces? >> str(',') >> spaces? }
      rule(:digit) { match('[0-9]') }

      rule(:text) { match('[^\s:,=\[\]\{\}#]').repeat(1).as(:text) }

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
          str('\\') >> any | str('"').absent? >> any
        ).repeat.as(:string) >> str('"') |
        str("'") >> (
          str('\\') >> any | str("'").absent? >> any
        ).repeat.as(:string) >> str("'")
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

      rule(:value) {
        array | object |
        string | number |
        str('true').as(:true) | str('false').as(:false) |
        str('null').as(:nil) | str('nil').as(:nil) |
        text
      }

      rule(:entry) {
        ((string | text).as(:k) >> spaces? >>
         (str(':') | str('=>')) >> spaces? >>
         value.as(:v)).as(:entry)
      }

      rule(:attribute) { (entry | value).as(:attribute) }

      rule(:blanks) { match('[ \t]').repeat(1) }

      rule(:blank_line) { blanks.maybe }
      rule(:line) {
        (
          str(' ').repeat.as(:indentation) >>
          match('[^ \n#"\']').repeat(1).as(:expname) >>
          (blanks >> attribute >> (comma >> attribute).repeat).as(:attributes).maybe
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

      def split(s)
        parse(s).collect { |l| l[:line] }
      end
    end

    #
    # A helper class to store the temporary tree while it gets read.
    #
    class Node

      attr_reader :parent, :indentation, :children

      def initialize(parent, indentation, line)

        @parent = parent
        @indentation = indentation
        @children = []

        @name = line[:expname].to_s.gsub(/-/, '_')

        atts = line[:attributes] || []
        atts = [ atts ] unless atts.is_a?(Array)

        @attributes = atts.inject({}) { |h, att|
          att = att[:attribute]
          if att.keys.first == :entry
            e = att[:entry]
            h[e[:k].values.first.to_s.gsub(/-/, '_')] = from_parslet(e[:v])
          else
            h[att.values.first.to_s.gsub(/-/, '_')] = nil
          end
          h
        }

        parent.children << self if parent
      end

      def from_parslet(elt)

        val = elt.values.first

        case elt.keys.first
          when :object
            (val.is_a?(Array) ? val : [ val ]).inject({}) { |h, e|
              k, v = Array(e[:entry]).collect { |e| e.last }
              h[from_parslet(k)] = from_parslet(v)
              h
            }
          when :array
            val.collect { |e| from_parslet(e) }
          when :string, :text
            val.to_s
          when :false
            false
          when :true
            true
          when :nil
            nil
          when :number
            sval = val.to_s
            sval.match(/[eE\.]/) ? Float(sval) : Integer(sval)
          else
            elt
        end
      end

      def to_a

        [ @name, @attributes, @children.collect { |c| c.to_a } ]
      end

      protected
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

    # The entry point : takes a radial string and returns, if possible,
    # a ruote tree.
    #
    def self.read(s)

      parser = Parser.new

      lines = parser.split("\n#{s}\n")

      root = PreRoot.new(s.strip.split("\n").first + '...')
      current = root

      lines.each do |line|

        # determine parent

        ind = line[:indentation].to_s.length

        if ind > current.indentation
          parent = current
        elsif ind == current.indentation
          parent = current.parent
        else # ind < current.indentation
          parent = current
          while ind <= parent.indentation
            parent = parent.parent
          end
        end

        # then create it

        current = Node.new(parent, ind, line)
      end

      root.to_a

    rescue Parslet::ParseFailed => e
      class << e; attr_accessor :error_tree; end
      e.error_tree = parser.root.error_tree
      raise e
    end
  end
end

