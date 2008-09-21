#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
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
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'yaml'
require 'openwfe/rexml'
require 'openwfe/service'
require 'openwfe/contextual'
require 'openwfe/util/treechecker'
require 'openwfe/util/xml'
require 'openwfe/util/json'
require 'openwfe/expressions/rprocdef'


module OpenWFE

  #
  # A process definition parser.
  #
  # Currently supports XML, Ruby process pdefinitions, YAML and JSON.
  #
  class DefParser < Service
    include OwfeServiceLocator

    #
    # a static version of the parse method,
    # by default checks the tree if it's Ruby code that is passed.
    #
    def self.parse (pdef, use_ruby_treechecker=true)

      #
      # preparing a small ad-hoc env (app context) for this parsing

      ac = { :use_ruby_treechecker => use_ruby_treechecker }

      ac[:s_tree_checker] = TreeChecker.new(:s_tree_checker, ac)
      ac[:s_def_parser] = DefParser.new(:s_def_parser, ac)

      ac[:s_def_parser].parse(pdef)
    end

    #
    # the classical initialize() of Ruote services
    #
    def initialize (service_name, application_context)
      super
    end

    #
    # in : a process pdefinition
    # out : a tree [ name, attributes, children ]
    #
    def parse (pdef)

      return pdef \
        if pdef.is_a?(Array)

      return parse_string(pdef) \
        if pdef.is_a?(String)

      return pdef.do_make \
        if pdef.is_a?(ProcessDefinition) or pdef.is_a?(Class)

      return pdef.to_a \
        if pdef.is_a?(SimpleExpRepresentation)
          # for legacy stuff

      raise "cannot handle pdefinition of class #{pdef.class.name}"
    end

    def parse_string (pdef)

      pdef = pdef.strip

      return parse_xml(pdef) if pdef[0, 1] == '<'

      return YAML.load(pdef) if pdef[0, 4] == '--- '

      (json = (OpenWFE::Json.from_json(pdef) rescue nil)) and return json

      #
      # else it's some ruby code to eval

      get_tree_checker.check pdef

      # green for eval...

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

  #
  # A set of methods for manipulating / querying a process expression tree
  #
  module ExpressionTree

    #
    # Extracts the description out of a process definition tree.
    #
    # TODO #14964 : add language support here
    #
    def self.get_description (tree)

      tree.last.each do |child|
        next unless child.is_a?(Array)
        return child.last.first if child.first == 'description'
      end

      nil
    end

    #
    # Returns a string containing the ruby code that generated this
    # raw representation tree.
    #
    def self.to_code_s (tree, indentation = 0)

      s = ''
      tab = '  '
      ind = tab * indentation

      s << ind
      s << OpenWFE::make_safe(tree.first)

      sa = ''
      tree[1].each do |k, v|
        #v = "'#{v}'" if v.is_a?(String)
        #v = ":#{v}" if v.is_a?(Symbol)
        v = v.inspect
        sa << ", :#{OpenWFE::to_underscore(k)} => #{v}"
      end
      s << sa[1..-1] if sa.length > 0

      if tree.last.length > 0
        if tree.last.size == 1 and tree.last.first.class == String
          # maybe could work for things that are not string either...
          s << " '#{tree.last.first}'"
        else
          s << " do\n"
          tree.last.each do |child|
            #if child.respond_to?(:to_code_s)
            if child.is_a?(Array) and child.size == 3 # and ...
              s << to_code_s(child, indentation + 1)
            else
              s << ind
              s << tab
              s << "'#{child.to_s}'" # inspect instead of to_s ?
            end
            s << "\n"
          end
          s << ind
          s << "end"
        end
      end

      s
    end

    #
    # Turns the expression tree into an XML process definition
    #
    def self.to_xml (tree)

      elt = REXML::Element.new tree.first.to_s

      tree[1].each do |k, v|

        if k == 'value' and (not v.is_a?(String))
          elt << OpenWFE::Xml::to_rexml(v)
        else
          elt.attributes[k] = v
        end
      end

      tree.last.each do |child|

        #if child.kind_of?(SimpleExpRepresentation)
        if child.is_a?(Array) and child.size == 3

          elt << to_xml(child)
        else

          elt << REXML::Text.new(child.to_s)
        end
      end

      elt
    end

    #
    # Returns an XML string
    #
    def self.to_s (tree, indent=-1)

      d = REXML::Document.new
      d << to_xml(tree)
      s = ''
      d.write s, indent
      s
    end
  end
end

