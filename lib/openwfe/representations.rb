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

require 'openwfe/util/xml'


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
    def self.launchitem_to_xml (li, options={})

      builder(options) do |xml|
        xml.launchitem do
          xml.workflow_definition_url(li.workflow_definition_url)
          xml.attributes do
            hash_to_xml(li.attributes, options)
          end
        end
      end
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

    def self.fei_to_xml (fei, options={})

      builder(options) do |xml|
        xml.flow_expression_id do
          FlowExpressionId::FIELDS.each do |f|
            xml.tag! f.to_s, fei.send(f)
          end

          xml.fei_short fei.to_s
            # a short, 1 string version of the fei
        end
      end
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
    def self.workitem_to_xml (wi, options={})

      builder(options) do |xml|

        atts = {}
        atts['href'] = wi.uri if wi.uri

        xml.workitem(atts) do

          fei_to_xml(wi.fei, options)

          xml.last_modified to_httpdate(wi.last_modified)

          xml.participant_name wi.participant_name

          xml.dispatch_time to_httpdate(wi.dispatch_time)
          #xml.filter ...
          xml.store wi.store

          xml.attributes do
            hash_to_xml wi.attributes, options
          end
        end
      end
    end

    #
    # Extracts an [InFlow]WorkItem instance from some XML.
    #
    def self.workitem_from_xml (xml)

      root = to_element xml, 'workitem'

      wi = InFlowWorkItem.new

      wi.uri = root.attribute('href')
      wi.uri = wi.uri.value if wi.uri

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

    #--
    # processes (instances of ProcessStatus)
    #++

    def self.href (options, args)
      href = options[:href]
      href ? href.call(*args) : nil
    end

    def self.process_to_xml (p, options={ :indent => 2 })

      builder(options) do |xml|

        xml.process :href => href(options, [ :processes, p.wfid ]) do

          xml.wfid p.wfid
          xml.wfname p.wfname
          xml.wfrevision p.wfrevision

          xml.launch_time p.launch_time
          xml.paused p.paused

          xml.timestamp p.timestamp.to_s

          xml.tags do
            p.tags.each { |t| xml.tag t }
          end

          xml.branches p.branches

          options[:tag] = 'variables'
          hash_to_xml(p.variables, options)

          xml.scheduled_jobs do
            p.scheduled_jobs.each do |j|
              xml.job do
                xml.type j.class.name
                xml.schedule_info j.schedule_info
                xml.next_time j.next_time.to_s
                xml.tags do
                  j.tags.each { |t| xml.tag t }
                end
              end
            end
          end

          xml.active_expressions :href => href(options, [ :expressions, p.wfid ]) do

            p.expressions.each do |fexp|

              fei = fexp.fei

              xml.expression(
                "#{fei.to_s}",
                :short => fei.to_web_s)
                #:href => fei.href(request))
            end
          end

          xml.errors :href => href(options, [ :errors, p.wfid ]), :count => p.errors.size do
            p.errors.each do |k, v|
              xml.error do
                #xml.stacktrace do
                #  xml.cdata! "\n#{v.stacktrace}\n"
                #end
                xml.fei v.fei.to_s
                xml.message v.stacktrace.split("\n")[0]
              end
            end
          end

          xml.tree(
            p.all_expressions.tree.to_json,
            :href => href(options, [ :processes, p.wfid, :tree ]))
        end
      end
    end
  end
end

