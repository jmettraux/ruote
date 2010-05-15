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


require 'uri'
require 'open-uri'
require 'rufus/json'
require 'ruote/parser/ruby_dsl' # just making sure it's loaded
require 'ruote/parser/xml'


module Ruote

  #
  # A process definition parser.
  #
  # Can parse XML, JSON, Ruby (and more) process definition representations.
  #
  class Parser

    def initialize (context)

      @context = context
    end

    # Turns the input into a ruote syntax tree (raw process definition).
    # This method is used by engine.launch(x) for example.
    #
    def parse (definition)

      return definition if definition.is_a?(Array) and definition.size == 3

      (return XmlParser.parse(definition)) rescue nil
      (return Rufus::Json.decode(definition)) rescue nil
      (return ruby_eval(definition)) rescue nil

      if definition.index("\n") == nil

        raise ArgumentError.new(
          "remote process definitions are not allowed"
        ) if Ruote::Parser.remote?(definition) && @context['remote_definition_allowed'] != true

        return parse(open(definition).read)
      end

      raise ArgumentError.new(
        "doesn't know how to parse definition (#{definition.class}) " +
        "or error in process definition")
    end

    # Class method for parsing process definition (XML, Ruby, from file or
    # from a string, ...) to syntax trees. Used by ruote-fluo for example.
    #
    def self.parse (d)

      unless @parser

        require 'ostruct'
        require 'ruote/util/treechecker'

        @parser = Ruote::Parser.new(
          OpenStruct.new('treechecker' => Ruote::TreeChecker.new({})))
      end

      @parser.parse(d)
    end

    # Turns the given process definition tree (ruote syntax tree) to an XML
    # String.
    #
    # Mainly used by ruote-fluo.
    #
    def self.to_xml (tree, options={})

      require 'builder'

      # TODO : deal with "participant 'toto'"

      builder(options) do |xml|

        atts = tree[1].dup

        t = atts.find { |k, v| v == nil }
        if t
          atts.delete(t.first)
          key = tree[0] == 'if' ? 'test' : 'ref'
          atts[key] = t.first
        end

        atts = atts.inject({}) { |h, (k, v)| h[k.to_s.gsub(/\_/, '-')] = v; h }

        if tree[2].empty?
          xml.tag!(tree[0], atts)
        else
          xml.tag!(tree[0], atts) do
            tree[2].each { |child| to_xml(child, options) }
          end
        end
      end
    end

    # Turns the given process definition tree (ruote syntax tree) to a Ruby
    # process definition (a String containing that ruby process definition).
    #
    # Mainly used by ruote-fluo.
    #
    def self.to_ruby (tree, level=0)

      expname = tree[0]

      expname = 'Ruote.process_definition' if level == 0 && expname == 'define'

      s = "#{'  ' * level}#{expname}#{atts_to_ruby(tree[1])}"

      return "#{s}\n" if tree[2].empty?

      s << " do\n"
      tree[2].each { |child| s << to_ruby(child, level + 1) }
      s << "#{'  ' * level}end\n"

      s
    end

    # Turns the process definition tree (ruote syntax tree) to a JSON String.
    #
    def self.to_json (tree)

      tree.to_json
    end

    # Returns true if the defintion is a remote URI
    #
    def self.remote? (definition)

      u = URI.parse(definition)

      (u.scheme != nil) && ( ! ('A'..'Z').include?(u.scheme))
    end

    protected

    # Evaluates the ruby string in the code, but at fist, thanks to the
    # treechecker, makes sure it doesn't code malicious ruby code (at least
    # tries very hard).
    #
    def ruby_eval (s)

      @context.treechecker.check(s)
      eval(s)

    rescue Exception => e
      #puts '=' * 80
      #p s
      #puts '-' * 80
      #puts e
      #e.backtrace.each { |l| puts l }
      raise ArgumentError.new('probably not ruby')
    end

    # A convenience method when building XML
    #
    def self.builder (options={}, &block)

      if b = options[:builder]
        block.call(b)
      else
        b = Builder::XmlMarkup.new(:indent => (options[:indent] || 0))
        options[:builder] = b
        b.instruct! unless options[:instruct] == false
        block.call(b)
        b.target!
      end
    end

    # As used by to_ruby.
    #
    def self.atts_to_ruby (atts)

      return '' if atts.empty?

      s = []

      t = atts.find { |k, v| v == nil }
      s << t.first.inspect if t

      s = atts.inject(s) { |a, (k, v)|
        a << ":#{k} => #{v.inspect}" if t.nil? || k != t.first
        a
      }.join(', ')

      s.length > 0 ? " #{s}" : s
    end
  end
end

