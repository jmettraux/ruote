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

  #
  # Simple methods for converting launchitems and workitems from and to
  # XML.
  #
  # There are also the from_xml(xml) and the to_xml(object) methods
  # that are interesting (though limited).
  #
  module Xml

    #--
    # launchitems
    #++

    #
    # Turns a launchitem into an XML String
    #
    def self.launchitem_to_xml (li, indent=0)

      b = Builder::XmlMarkup.new :indent => indent

      b.instruct!

      b.launchitem do
        b.workflow_definition_url li.workflow_definition_url
        b.attributes do
          hash_to_xml b, li.attributes
        end
      end

      b.target!
    end

    #
    # Given some XML (string or rexml doc/elt), extracts the LaunchItem
    # instance.
    #
    def self.launchitem_from_xml (xml)

      root = to_element xml, 'launchitem'

      li = LaunchItem.new

      li.wfdurl = text root, 'workflow_definition_url'

      li.attributes = object_from_xml(
        root.owfe_first_elt_child('attributes').owfe_first_elt_child)

      li
    end

    #--
    # flow expression id
    #++

    def self.fei_to_xml (fei, indent=0)

      b = Builder::XmlMarkup.new :indent => indent

      b.instruct!

      _fei_to_xml b, fei

      b.target!
    end

    def self.fei_from_xml (xml)

      xml = to_element xml, 'flow_expression_id'

      fei = FlowExpressionId.new

      FlowExpressionId::FIELDS.each do |f|
        fei.send "#{f}=", text(xml, f.to_s)
      end

      fei
    end

    #--
    # workitems
    #++

    #
    # Turns an [InFlow]WorkItem into some XML.
    #
    def self.workitem_to_xml (wi, indent=0)

      b = Builder::XmlMarkup.new :indent => indent

      b.instruct!

      _workitem_to_xml b, wi

      b.target!
    end

    #
    # Pipes a workitem into a XML builder
    #
    def self._workitem_to_xml (builder, wi, top_attributes={})

      builder.workitem(top_attributes) do

        _fei_to_xml builder, wi.fei # flow expression id

        builder.last_modified to_httpdate(wi.last_modified)

        builder.participant_name wi.participant_name

        builder.dispatch_time to_httpdate(wi.dispatch_time)
        #builder.filter ...
        builder.store wi.store

        builder.attributes do
          hash_to_xml builder, wi.attributes
        end
      end
    end

    #
    # Extracts an [InFlow]WorkItem instance from some XML.
    #
    def self.workitem_from_xml (xml)

      root = to_element xml, 'workitem'

      wi = InFlowWorkItem.new

      wi.fei = fei_from_xml root.elements['flow_expression_id']

      wi.last_modified = from_httpdate(text(root, 'last_modified'))
      wi.participant_name = text root, 'participant_name'
      wi.dispatch_time = from_httpdate(text(root, 'dispatch_time'))

      wi.attributes = object_from_xml(
        root.owfe_first_elt_child('attributes').owfe_first_elt_child)

      wi
    end

    #
    # Extracts a list of workitems from some XML.
    #
    def self.workitems_from_xml (xml)

      root = to_element xml, 'workitems'

      root.owfe_elt_children.collect do |elt|
        workitem_from_xml elt
      end
    end

    #--
    # cancelitems
    #++

    def self.cancelitem_to_xml (ci)

      nil # TODO : implement me
    end

    def self.cancelitem_from_xml (xml)

      nil # TODO : implement me
    end

    #
    # An 'internal' method, turning an object into some XML.
    #
    def self.object_to_xml (xml, o)

      return xml.true if o == true
      return xml.false if o == false
      return xml.null if o == nil
      return xml.number(o.to_s) if o.is_a?(Numeric)

      return hash_to_xml(xml, o) if o.is_a?(Hash)
      return array_to_xml(xml, o) if o.is_a?(Array)

      return xml.string(o.to_s) if o.is_a?(String)

      xml.object o.to_s
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
    # from_xml, the other way
    #
    def self.to_xml (o, indent=0, instruct = false)

      b = Builder::XmlMarkup.new :indent => indent

      b.instruct! if instruct

      object_to_xml b, o

      b.target!
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

      def self._fei_to_xml (xml, fei)

        xml.flow_expression_id do
          FlowExpressionId::FIELDS.each do |f|
            xml.tag! f.to_s, fei.send(f)
          end

          xml.fei_short fei.to_s
            # a short, 1 string version of the fei
        end
      end

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

      def self.hash_to_xml (xml, h)

        xml.hash do
          h.each do |k, v|
            xml.entry do
              object_to_xml xml, k
              object_to_xml xml, v
            end
          end
        end
      end

      def self.array_to_xml (xml, a)

        xml.array do
          a.each { |o| object_to_xml xml, o }
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

