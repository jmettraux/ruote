#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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
require 'yaml'
require 'openwfe/rexml'
require 'openwfe/service'
require 'openwfe/contextual'
require 'openwfe/util/treechecker'
require 'openwfe/util/xml'
require 'openwfe/util/json'
require 'openwfe/expressions/rprocdef'
require 'openwfe/expressions/expression_map'

require 'rufus/verbs' # sudo gem install 'rufus-verbs'


module OpenWFE

  #
  # A process definition parser.
  #
  # Currently supports XML, Ruby process definitions, YAML and JSON.
  #
  class DefParser < Service
    include OwfeServiceLocator

    #
    # a static version of the parse method,
    # by default checks the tree if it's Ruby code that is passed.
    #
    def self.parse (pdef, use_ruby_treechecker=true)

      # preparing a small ad-hoc env (app context) for this parsing

      ac = { :use_ruby_treechecker => use_ruby_treechecker }

      ac[:s_tree_checker] = TreeChecker.new(:s_tree_checker, ac)
      ac[:s_def_parser] = DefParser.new(:s_def_parser, ac)
      ac[:s_expression_map] = ExpressionMap.new

      ac[:s_def_parser].parse(pdef)
    end

    #
    # the classical initialize() of Ruote services
    #
    def initialize (service_name, application_context)
      super
    end

    #
    # This is the only point in the expression pool where an URI
    # is read, so this is where the :remote_definitions_allowed
    # security check is enforced.
    #
    def read_uri (uri)

      return File.read(uri) if uri.to_s.match(/^[a-zA-Z]:[\/\\]/)
        # seems like we're on windows, well... A:/ ?

      u = URI.parse(uri.to_s)

      raise(':remote_definitions_allowed is set to false') \
        if (ac[:remote_definitions_allowed] != true and
          u.scheme and
          u.scheme != 'file')

      f = Rufus::Verbs.fopen(u) # Rufus::Verbs is OK with redirections
      result = f.read
      f.close if f.respond_to?(:close)

      result
    end

    #
    # Returns the tree representation into behind the param (uri, string, ...)
    #
    def determine_rep (param)

      param = param.is_a?(URI) ? read_uri(param) : param
      parse(param)
    end

    #
    # in : a process pdefinition
    # out : a tree [ name, attributes, children ]
    #
    def parse (pdef)

      tree = case pdef
        when Array then pdef
        when String then parse_string(pdef)
        when Class then pdef.do_make
        when ProcessDefinition then pdef.do_make
        when SimpleExpRepresentation then pdef.do_make # legacy...
        else
          raise "cannot handle pdefinition of class #{pdef.class.name}"
      end

      tree = [ 'define', { 'name' => 'NoName', 'revision' => '0' }, [ tree ] ] \
        unless get_expression_map.is_definition?(tree.first)
          #
          # making sure the first expression in the tree is a DefineExpression
          # (an alias for 'process-definition')

      tree
    end

    X_START = /^</
    Y_START = /^--- /
    J_ARRAY = /^\[.*\]$/
      #
      # TODO : place that somewhere in utils/

    def parse_string (pdef)

      pdef = pdef.strip

      return parse_xml(pdef) if pdef.match(X_START)
      return YAML.load(pdef) if pdef.match(Y_START)

      #(json = (OpenWFE::Json.from_json(pdef) rescue nil)) and return json
      return OpenWFE::Json.from_json(pdef) if pdef.match(J_ARRAY)

      #
      # else it's some ruby code to eval

      get_tree_checker.check(pdef)

      # no exception, green for eval...

      ProcessDefinition.eval_ruby_process_definition(pdef)
    end

    #
    # The process definition is expressed as XML, turn that into
    # an expression tree.
    #
    def parse_xml (xml)

      xml = REXML::Document.new(xml) \
        if xml.is_a?(String)

      xml = xml.root \
        if xml.is_a?(REXML::Document)

      if xml.is_a?(REXML::Text)

        s = xml.to_s.strip

        return s if s.length > 0

        return nil
      end

      return nil if xml.is_a?(REXML::Comment)

      # then it's a REXML::Element

      rep = [
        xml.name,
        xml.attributes.inject({}) { |r, (k, v)| r[k] = v; r },
        [] ]

      xml.children.each do |c|

        r = parse_xml(c)

        rep.last << r if r
      end

      rep
    end
  end
end

