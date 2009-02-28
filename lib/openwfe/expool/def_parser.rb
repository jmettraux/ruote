#--
# Copyright (c) 2008-2009, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
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

    def parse_string (pdef)

      pdef = pdef.strip

      return parse_xml(pdef) if pdef[0, 1] == '<'

      return YAML.load(pdef) if pdef[0, 4] == '--- '

      (json = (OpenWFE::Json.from_json(pdef) rescue nil)) and return json

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

        r = parse_xml c

        rep.last << r if r
      end

      rep
    end
  end
end

