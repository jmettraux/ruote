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

require 'sourcify'
require 'ruote/util/ometa'


module Ruote

  # Not really a reader, more an AST builder.
  #
  #   pdef = Ruote.define :name => 'take_out_garbage' do
  #     sequence do
  #       take_out_regular_garbage
  #       take_out_glass
  #       take_out_paper
  #     end
  #   end
  #
  #   engine.launch(pdef)
  #
  def self.define(*attributes, &block)

    RubyDsl.create_branch('define', attributes, &block)
  end

  # Same as Ruote.define()
  #
  #   pdef = Ruote.process_definition :name => 'take_out_garbage' do
  #     sequence do
  #       take_out_regular_garbage
  #       take_out_paper
  #     end
  #   end
  #
  #   engine.launch(pdef)
  #
  def self.process_definition(*attributes, &block)

    define(*attributes, &block)
  end

  # Similar in purpose to Ruote.define and Ruote.process_definition but
  # instead of returning a [process] definition, returns the tree.
  #
  #   tree = Ruote.process_definition :name => 'take_out_garbage' do
  #     sequence do
  #       take_out_regular_garbage
  #       take_out_paper
  #     end
  #   end
  #
  #   p tree
  #     # => [ 'sequence', {}, [ [ 'take_out_regular_garbage', {}, [] ], [ 'take_out_paper', {}, [] ] ] ],
  #
  # This is useful when modifying a process instance via methods like re_apply :
  #
  #   engine.re_apply(
  #     fei,
  #     :tree => Ruote.to_tree {
  #       sequence do
  #         participant 'alfred'
  #         participant 'bob'
  #       end
  #     })
  #       #
  #       # cancels the segment of process at fei and replaces it with
  #       # a simple alfred-bob sequence.
  #
  def self.to_tree(&block)

    RubyDsl.create_branch('x', {}, &block).last.first
  end

  class << self
    alias tree to_tree
  end

  # :nodoc:
  #
  module RubyDsl

    class BranchContext < Ruote::BlankSlate

      def initialize(name, attributes)

        @name = name
        @attributes = attributes
        @children = []
      end

      def method_missing(m, *args, &block)

        @children.push(Ruote::RubyDsl.create_branch(m.to_s, args, &block))
      end

      def to_a

        [ @name, @attributes, @children ]
      end
    end

    def self.create_branch(name, attributes, &block)

      name = name[1..-1] while name[0, 1] == '_'

      h = attributes.each_with_object({}) { |a, h1|

        if a.is_a?(Hash)
          h1.merge!(a)
        else
          h1[a] = nil
        end

      }.remap { |(k, v), h1|

        k = k.is_a?(Regexp) ? k.inspect : k.to_s
        h1[k] = to_json(v)
      }

      c = BranchContext.new(name, h)
      c.instance_eval(&block) if block

      c.to_a
    end

    def self.to_json(v)

      case v
        when Symbol; v.to_s
        when Regexp; v.inspect
        when Array; v.collect { |e| to_json(e) }
        when Hash; v.remap { |(k, v), h| h[to_json(k)] = to_json(v) }
        when Proc; v.to_raw_source + "\n"
        else v
      end
    end
  end

  #
  # The same .read and .understands? method as the other readers are found here.
  #
  module RubyReader

    # Returns true if s seems to contain a Ruby process definition
    #
    def self.understands?(s)

      s.match(
        /\bRuote\.(process_definition|workflow_definition|define)\b/
      ) != nil
    end

    # Evaluates the ruby string in the code, but at fist, thanks to the
    # treechecker, makes sure it doesn't code malicious ruby code (at least
    # tries very hard).
    #
    def self.read(s, treechecker)

      treechecker.definition_check(s)
      eval(s)

    rescue SyntaxError => se
      #p se
      raise ArgumentError.new("Ruby syntax error : #{se.message}")
    end
  end
end

