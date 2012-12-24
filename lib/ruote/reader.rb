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

require 'uri'
require 'open-uri'
require 'rufus/json'
require 'ruote/reader/xml'
require 'ruote/reader/json'
require 'ruote/reader/radial'
require 'ruote/reader/ruby_dsl' # just making sure it's loaded
require 'ruote/util/mpatch'
require 'ruote/util/subprocess'


module Ruote

  #
  # A process definition reader.
  #
  # Can reader XML, JSON, Ruby (and more) process definition representations.
  #
  class Reader

    # This error is emitted by the reader when it failed to read a process
    # definition (passed as a string).
    #
    class Error < ArgumentError

      attr_reader :definition
      attr_reader :ruby, :radial, :xml, :json

      def initialize(definition)
        super('cannot read process definition')
        @definition = definition
      end

      def <<(args)
        type, error = args
        type = type.to_s.match(/^Ruote::(.+)Reader$/)[1].downcase
        instance_variable_set("@#{type}", error)
      end

      # Returns the most likely error cause...
      #
      def cause
        @ruby || @radial || @xml || @json
      end
    end

    def initialize(context)

      @context = context
    end

    # Turns the input into a ruote syntax tree (raw process definition).
    # This method is used by engine.launch(x) for example.
    #
    def read(definition)

      return definition if Ruote.is_tree?(definition)

      raise ArgumentError.new(
        "cannot read process definitions of class #{definition.class}"
      ) unless definition.is_a?(String)

      if is_uri?(definition)

        if
          Ruote::Reader.remote?(definition) &&
          @context['remote_definition_allowed'] != true
        then
          raise ArgumentError.new('remote process definitions are not allowed')
        end

        return read(open(definition).read)
      end

      tree = nil
      error = Error.new(definition)

      [
        Ruote::RubyReader, Ruote::RadialReader,
        Ruote::XmlReader, Ruote::JsonReader
      ].each do |reader|

        next if tree
        next unless reader.understands?(definition)

        begin
          tree = reader.read(definition, @context.treechecker)
        rescue => e
          error << [ reader, e ]
        end
      end

      tree || raise(error)
    end

    # Class method for parsing process definition (XML, Ruby, from file or
    # from a string, ...) to syntax trees. Used by ruote-fluo for example.
    #
    def self.read(d)

      unless @reader

        require 'ostruct'
        require 'ruote/svc/treechecker'

        @reader = Ruote::Reader.new(
          OpenStruct.new('treechecker' => Ruote::TreeChecker.new({})))
      end

      @reader.read(d)
    end

    # Turns the given process definition tree (ruote syntax tree) to an XML
    # String.
    #
    # Mainly used by ruote-fluo.
    #
    def self.to_xml(tree, options={})

      s = StringIO.new
      s.puts('<?xml version="1.0" encoding="UTF-8"?>')

      _to_xml(tree, options[:indent], 0, s)

      s.string
    end

    # Not as good as the builder gem, but at least doesn't come bundled with
    # lib/blankslate.rb
    #
    def self._to_xml(tree, indent, level, s) # :nodoc:

      atts = tree[1].dup

      if t = atts.find { |k, v| v == nil }
        atts.delete(t.first)
        atts[tree[0] == 'if' ? 'test' : 'ref'] = t.first
      end

      atts = atts.remap { |(k, v), h| h[k.to_s.gsub(/\_/, '-')] = v }
      atts = atts.to_a.sort_by { |k, v| k }

      s.print ' ' * level

      s.print '<'
      s.print tree[0]

      if atts.any?
        s.print ' '
        s.print atts.collect { |k, v|
          "#{k}=#{v.is_a?(String) ? v.inspect : v.inspect.inspect}"
        }.join(' ')
      end

      if tree[2].empty?

        s.puts '/>'

      else

        s.puts '>'

        tree[2].each { |child| _to_xml(child, indent, level + (indent || 0), s) }

        s.print ' ' * level
        s.print '</'
        s.print tree[0]
        s.puts '>'
      end
    end

    # Turns the given process definition tree (ruote syntax tree) to a Ruby
    # process definition (a String containing that ruby process definition).
    #
    # Mainly used by ruote-fluo.
    #
    def self.to_ruby(tree, level=0)

      expname = tree[0]
      expname = 'Ruote.process_definition' if level == 0 && expname == 'define'

      s = '  ' * level + expname + atts_to_ruby(tree[1])

      return "#{s}\n" if tree[2].empty?

      s << " do\n"
      tree[2].each { |child| s << to_ruby(child, level + 1) }
      s << "#{'  ' * level}end\n"

      s
    end

    # Turns the given tree into a radial process definition.
    #
    def self.to_radial(tree, level=0)

      s = '  ' * level + tree[0] + atts_to_radial(tree[1]) + "\n"

      return s if tree[2].empty?

      tree[2].inject(s) { |ss, child| ss << to_radial(child, level + 1); ss }
    end

    # Produces an expid annotated radial version of the process definition,
    # like:
    #
    #   0  define name: "nada"
    #     0_0  sequence
    #       0_0_0  alpha
    #       0_0_1  participant "bravo", timeout: "2d", on_board: true
    #
    # Can be useful when debugging noisy engines.
    #
    def self.to_expid_radial(tree)

      lines = to_raw_expid_radial(tree, '0')
      max = lines.collect { |l| l[1].length }.max

      lines.collect { |l|
        "%#{max}s  " % l[1] + "  " * l[0] + l[2] + l[3]
      }.join("\n")
    end

    # Used by .to_expid_radial. Outputs an array of 'lines'. Each line
    # is a process definition line, represented as an array:
    #
    #   [ level, expid, name, atts ]
    #
    # Like in:
    #
    #   [[0, "0", "define", " name: \"nada\""],
    #    [1, "0_0", "sequence", ""],
    #    [2, "0_0_0", "alpha", ""],
    #    [2, "0_0_1", "participant", " \"bravo\", timeout: \"2d\"]]
    #
    def self.to_raw_expid_radial(tree, expid='0')

      i = -1

      [
        [ expid.split('_').size - 1, expid, tree[0], atts_to_radial(tree[1]) ]
      ] +
      tree[2].collect { |t|
        i = i + 1; to_raw_expid_radial(t, "#{expid}_#{i}")
      }.flatten(1)
    end

    # Turns the process definition tree (ruote syntax tree) to a JSON String.
    #
    def self.to_json(tree)

      tree.to_json
    end

    # Returns true if the defintion is a remote URI
    #
    def self.remote?(definition)

      u = URI.parse(definition)

      (u.scheme != nil) && ( ! ('A'..'Z').include?(u.scheme))
    end

    protected

    # Minimal test. Used by #read.
    #
    def is_uri?(s)

      return false if s.index("\n")

      ((URI.parse(s); true) rescue false)
    end

    def self.to_ra_string(o)

      return 'nil' if o == nil

      s = o.to_s

      return s if [ true, false ].include?(o)

      i = o.inspect

      return i if %w[ true false nil ].include?(s)
      return i if s.match(/[\s:]/)
      return s if i == "\"#{o.to_s}\""

      i
    end

    # split the txt => nil entry and sorts the rest of the attributes.
    #
    def self.split_atts(atts)

      atts = atts.to_a.sort_by { |k, v| k }
      txt = atts.find { |k, v| v == nil }
      atts.delete(txt) if txt

      [ txt ? txt.first : nil, atts ]
    end

    # As used by to_radial
    #
    def self.atts_to_radial(atts, &block)

      s = []
      txt, atts = split_atts(atts)

      s << to_ra_string(txt) if txt
      s += atts.collect { |k, v| "#{to_ra_string(k)}: #{to_ra_string(v)}" }

      s = s.join(', ')

      s.length > 0 ? " #{s}" : s
    end

    # As used by to_ruby
    #
    def self.atts_to_ruby(atts, &block)

      s = []
      txt, atts = split_atts(atts)

      s << txt.inspect if txt
      s += atts.collect { |k, v| ":#{k} => #{v.inspect}" }

      s = s.join(', ')

      s.length > 0 ? " #{s}" : s
    end
  end
end

