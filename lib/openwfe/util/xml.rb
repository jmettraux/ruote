#
#--
# Copyright (c) 2008 John Mettraux, OpenWFE.org
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

require 'openwfe/rexml'
require 'builder'


#
# Reopening REXML::Element to add a few helper methods (prefixed with
# an 'owfe_').
# Not too happy with this solution, but the prefix should prevent
# collisions
#
class REXML::Element

  #
  # Returns the first child that is a REXML::Element or the first child
  # that is an element and that has the given name.
  #
  def owfe_first_elt_child (name=nil)

    children.find do |c|
      c.is_a?(REXML::Element) and (( ! name) or c.name == name)
    end
  end

  #
  # Returns all the children that are instances of REXML::Element
  #
  def owfe_elt_children

    children.find_all { |c| c.is_a?(REXML::Element) }
  end
end


module OpenWFE

  module Xml

    #
    # This method is used by all the to_xml methods, it ensures a builder
    # is available via the :builder key in the options hash.
    #
    # Usage example :
    #
    #    builder(options) do |xml|
    #      xml.hash do
    #        h.each do |k, v|
    #          xml.entry do
    #            object_to_xml k, options
    #            object_to_xml v, options
    #          end
    #        end
    #      end
    #    end
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

    def self.object_to_xml (o, options={})

      builder(options) do |xml|
        case o
          when true then xml.true
          when false then xml.false
          when nil then xml.null
          when Numeric then xml.number(o.to_s)
          when Hash then hash_to_xml(o, options)
          when Array then array_to_xml(o, options)
          when String then xml.string(o.to_s)
          when Symbol then xml.symbol(o.to_s)
          else xml.object(o.to_s)
        end
      end
    end

    #
    # an alias
    #
    def self.to_xml (o, options={})

      object_to_xml(o, options)
    end

    #
    # Turns XML into an object (quite basic though).
    #
    # For example :
    #
    #    <array>
    #      <string>alpha</string>
    #      <number>2</number>
    #      <number>2.3</number>
    #      <false/>
    #      <null/>
    #    </array>
    #
    # =>
    #
    #   [ 'alpha', 2, 2.3, false, nil ]
    #
    def self.from_xml (xml)

      xml = to_element xml

      object_from_xml xml
    end

    #
    # Like to_xml(o) but instead of returning a String, returns a REXML
    # Element
    #
    def self.to_rexml (o)

      d = REXML::Document.new(to_xml(o))
      d.root
    end

    private

      def self.to_httpdate (t)

        return "" unless t
        t.httpdate
      end

      def self.from_httpdate (s)

        return nil unless s
        return nil if s.strip == ""

        Time.httpdate s
      end

      #--
      # OUT
      #++

      def self.to_element (xml, root_name=nil)

        xml = if xml.is_a?(REXML::Element)
          xml
        elsif xml.is_a?(REXML::Document)
          xml.root
        else
          REXML::Document.new(xml).root
        end

        raise "not the XML of a #{root_name} ('#{xml.name}')" \
          if root_name and (xml.name != root_name)

        xml
      end

      def self.hash_to_xml (h, options={})

        tagname = options.delete(:tag) || 'hash'

        builder(options) do |xml|
          xml.tag! tagname do
            h.each do |k, v|
              xml.entry do
                object_to_xml k, options
                object_to_xml v, options
              end
            end
          end
        end
      end

      def self.array_to_xml (a, options={})

        builder(options) do |xml|
          xml.array do
            a.each { |o| object_to_xml(o, options) }
          end
        end
      end

      #--
      # IN
      #++

      #
      # Returns the text wrapped in the child elt with the given
      # name.
      #
      def self.text (parent, elt_name)

        parent.elements[elt_name].text
      end

      def self.object_from_xml (elt)

        name = elt.name
        text = elt.text

        return true if name == 'true'
        return false if name == 'false'
        return nil if name == 'null'

        if name == 'number'
          return text.to_f if text.index('.')
          return text.to_i
        end

        return hash_from_xml(elt) if name == 'hash'
        return array_from_xml(elt) if name == 'array'

        text # string / object
      end

      def self.hash_from_xml (elt)

        elt.owfe_elt_children.inject({}) do |r, e|

          children = e.owfe_elt_children

          k = object_from_xml children[0]
          v = object_from_xml children[1]

          r[k] = v

          r
        end
      end

      def self.array_from_xml (elt)

        elt.owfe_elt_children.inject([]) do |r, e|
          r << object_from_xml(e)
        end
      end
  end
end

