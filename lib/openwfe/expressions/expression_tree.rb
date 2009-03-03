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


module OpenWFE

  #
  # A set of methods for manipulating / querying a process expression tree
  #
  module ExpressionTree

    #
    # Returns true if the argument is a leaf.
    #
    def self.is_not_a_node? (o)

      (( ! o.is_a?(Array)) || o.size != 3 || ( ! o.first.is_a?(String)))
    end

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

      if single_string_child = (
        tree.last.size == 1 and tree.last.first.class == String
      )
        s << " '#{tree.last.first}'"
      end

      sa = tree[1].inject('') do |r, (k, v)|
        r << ", :#{OpenWFE::to_underscore(k)} => #{v.inspect}"
      end
      sa = sa[1..-1] unless single_string_child
      s << sa if sa

      if tree.last.length > 0
        if tree.last.size == 1 and tree.last.first.class == String
          # do nothing (already done)
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
      d.write(s, indent)
      s
    end

    #
    # This method is called by the expression pool when it is about
    # to launch a process, it will interpret the 'parameter' statements
    # in the process definition and raise an exception if the requirements
    # are not met.
    #
    def self.check_parameters (tree, workitem)

      extract_parameters(tree).each { |param| param.check(workitem) }
    end

    protected

    #
    # Extracts the [pseudo-]expression parameters at the top of the given
    # tree.
    #
    def self.extract_parameters (tree)

      r = []
      tree.last.each do |child|

        next if OpenWFE::ExpressionTree.is_not_a_node?(child)

        name = child.first.to_sym
        next unless (name == :parameter or name == :param)

        attributes = child[1]

        r << ProcessParameter.new(attributes)
      end
      r
    end
  end

  protected

  #
  # Encapsulating
  #   <parameter field="x" default="y" type="z" match="m" />
  #
  # Somehow I hate that param thing, Ruote is not a strongly typed language
  # ... Anyway Pat seems to use it.
  #
  class ProcessParameter

    def initialize (attributes)

      @field = to_s(attributes['field'])
      @match = to_s(attributes['match'])
      @default = to_s(attributes['default'])
      @type = to_s(attributes['type'])
    end

    #
    # Will raise an exception if this param requirement is not
    # met by the workitem.
    #
    def check (workitem)

      raise(
        ArgumentError.new("'parameter'/'param' without a 'field' attribute")
      ) unless @field

      field_value = workitem.attributes[@field]
      field_value ||= @default

      raise(
        ArgumentError.new("field '#{@field}' is missing")
      ) unless field_value

      check_match(field_value)

      enforce_type(workitem, field_value)
    end

    protected

    #
    # Used in the constructor to flatten everything to strings.
    #
    def to_s (o)
      o ? o.to_s : nil
    end

    #
    # Will raise an exception if it cannot coerce the type
    # of the value to the one desired.
    #
    def enforce_type (workitem, value)

      value = if not @type
        value
      elsif @type == 'string'
        value.to_s
      elsif @type == 'int' or @type == 'integer'
        Integer(value)
      elsif @type == 'float'
        Float(value)
      else
        raise
          "unknown type '#{@type}' for field '#{@field}'"
      end

      workitem.attributes[@field] = value
    end

    def check_match (value)

      return unless @match

      raise(
        ArgumentError.new("value of field '#{@field}' doesn't match")
      ) unless value.to_s.match(@match)
    end
  end
end

