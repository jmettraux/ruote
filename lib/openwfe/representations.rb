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

require 'openwfe/workitem'
require 'openwfe/expool/errorjournal'
require 'openwfe/engine/status_methods'
require 'openwfe/expressions/flowexpression'
require 'openwfe/util/xml'
require 'openwfe/util/json'


module OpenWFE

  #
  # Swaps from dots to underscores
  #
  #   swapdots "0_0_1" # => "0.0.1"
  #
  #   swapdots "0.0.1" # => "0_0_1"
  #
  def self.swapdots (s)

    s.index('.') ?
      s.gsub(/\./, '_') :
      s.gsub(/\_/, '.')
  end

  #
  # a 'plain' implementation of a link generator
  #
  class PlainLinkGenerator

    def links (item, hint)

      key = item.class
      content = if item.respond_to?(:first)
        item.first
      elsif item.respond_to?(:values)
        item.values.first
      end
      content = content.class if content
      content = hint if hint and (not content)
      key = [ key, content ] if content

      method = GENS[key] || (return [])

      send(method, item)
    end

    protected

      #
      # some kind of 'case'
      #
      GENS = {
        OpenWFE::InFlowWorkItem => 'workitem',
        [ Array, OpenWFE::InFlowWorkItem ] => 'workitems',
        OpenWFE::ProcessStatus => 'process',
        [ Array, OpenWFE::ProcessStatus ] => 'processes',
        OpenWFE::FlowExpression => 'expression',
        [ Hash, OpenWFE::FlowExpression ] => 'expressions'
      }

      #
      # Override me (message to ruote-rest and ruote-web2)
      #
      # (Warning : this method turns dots to underscores in the id)
      #
      def link (rel, res, id=nil)
        href = "/#{res}"
        href = "#{href}/#{OpenWFE.swapdots(id)}" if id
        [ href, rel ]
      end

      def gen_links (res, item, &block)
        if block
          [ link('via', res), link('self', res, block.call(item)) ]
        else
          [ link('via', ''), link('self', res) ]
        end
      end

      def workitem (item)
        gen_links('workitems', item) { |i| "#{i.fei.wfid}/#{i.fei.expid}" }
      end
      def workitems (item)
        gen_links('workitems', item)
      end

      def process (item)
        gen_links('processes', item) { |i| i.wfid } +
        [ link('related', 'processes', "#{item.wfid}/tree") ]
      end
      def processes (item)
        gen_links('processes', item)
      end

      def error (item)
        gen_links('errors', item) { |i| "#{i.fei.wfid}/#{i.fei.expid}" }
      end
      def errors (item)
        gen_links('errors', item)
      end

      def expression (item)
        gen_links('expressions', item) { |i|
          "#{i.fei.wfid}/#{i.fei.expid}" +
          i.is_a?(OpenWFE::Environment) ? 'e' : ''
        }
      end
      def expressions (item)
        gen_links('expressions', item)
      end
  end

  #
  # Insert some links (if found under options[:linkgen])
  #
  def self.rep_insert_links (item, options, target, hint, is_xml)

    linkgen = options[:linkgen] || (return target)
    linkgen = OpenWFE::PlainLinkGenerator.new if linkgen == :plain

    linkgen.links(item, hint).each do |l|

      atts = { 'href' => l[0], 'rel' => l[1] }
      atts['type'] = l[2] if l[2]

      if is_xml
        target.link(atts)
      else # Hash
        (target['links'] ||= []) << atts
      end
    end

    target
  end

  def Xml.rep_insert_links (item, options, xml, hint=nil)

    OpenWFE.rep_insert_links(item, options, xml, hint, true)
  end

  def Json.rep_insert_links (item, options, h, hint=nil)

    OpenWFE.rep_insert_links(item, options, h, hint, false)
  end

  #--
  # launchitems
  #++

  #
  # Turns a launchitem into an XML String
  #
  def Xml.launchitem_to_xml (li, options={})

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
  # (getting tolerant, also accepting <process/> representations)
  #
  def Xml.launchitem_from_xml (xml)

    li = LaunchItem.new

    root =
      to_element(xml, 'launchitem') ||
      to_element(xml, 'process')

    li.wfdurl =
      text(root, 'workflow_definition_url') ||
      text(root, 'definition_url')

    attributes =
      root.owfe_first_elt_child('attributes') ||
      root.owfe_first_elt_child('fields')

    li.attributes = attributes ?
      object_from_xml(attributes.owfe_first_elt_child) : {}

    definition = text(root, 'definition')
    li.attributes['__definition'] = definition if definition

    li
  end

  #
  # Turns a launchitem into a hash
  #
  def Json.launchitem_to_h (li)

    li.to_h
  end

  #
  # Creates a LaunchItem instance from a hash (or a JSON string)
  #
  def Json.launchitem_from_h (h_or_json)

    OpenWFE::LaunchItem.from_h(as_h(h_or_json))
  end

  #--
  # flow expression id
  #++

  def Xml.fei_to_xml (fei, options={})

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

  def Xml.fei_from_xml (xml)

    xml = to_element(xml, 'flow_expression_id')

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
  def Xml.workitem_to_xml (wi, options={})

    builder(options) do |xml|

      xml.workitem do

        rep_insert_links(wi, options, xml)

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
  # Turns a list of workitems into a XML document (String)
  #
  def Xml.workitems_to_xml (wis, options={})

    builder(options) do |xml|

      xml.workitems(
        #:href => options[:self] || OpenWFE::href(options, :workitems),
        :count => wis.size
      ) do

        rep_insert_links(wis, options, xml, OpenWFE::InFlowWorkItem)

        wis.each { |wi| workitem_to_xml(wi, options) }
      end
    end
  end

  #
  # Extracts an [InFlow]WorkItem instance from some XML.
  #
  def Xml.workitem_from_xml (xml)

    root = to_element(xml, 'workitem')

    wi = InFlowWorkItem.new

    self_link = root.elements["link[@rel='self']"]
    wi.uri = self_link ? self_link.attributes['href'] : nil

    wi.fei = fei_from_xml root.elements['flow_expression_id']

    wi.last_modified = from_httpdate(text(root, 'last_modified'))
    wi.participant_name = text(root, 'participant_name')
    wi.dispatch_time = from_httpdate(text(root, 'dispatch_time'))

    wi.attributes = object_from_xml(
      root.owfe_first_elt_child('attributes').owfe_first_elt_child)

    wi
  end

  #
  # Extracts a list of workitems from some XML.
  #
  def Xml.workitems_from_xml (xml)

    root = to_element(xml, 'workitems')

    root.owfe_elt_children.select { |elt|
      elt.name == 'workitem'
    }.collect { |elt|
      workitem_from_xml(elt)
    }
  end

  #
  # Turns an array of workitems into a hash
  #
  def Json.workitems_to_h (wis, opts={})

    h = { 'elements' =>  wis.collect { |wi| workitem_to_json(wi, opts) } }

    rep_insert_links(wis, opts, h, OpenWFE::InFlowWorkItem)
  end

  #
  # Turns a workitem into a hash
  #
  def Json.workitem_to_h (wi, opts={})

    rep_insert_links(wi, opts, wi.to_h)
  end

  #--
  # cancelitems
  #++

  def Xml.cancelitem_to_xml (ci)

    raise NotImplementedError.new('cancelitem_to_xml')
  end

  def Xml.cancelitem_from_xml (xml)

    raise NotImplementedError.new('cancelitem_from_xml')
  end

  def Json.cancelitem_to_h (ci)

    raise NotImplementedError.new('cancelitem_to_h')
  end

  def Json.cancelitem_from_h (h)

    raise NotImplementedError.new('cancelitem_from_h')
  end

  #--
  # processes (instances of ProcessStatus)
  #++

  def Xml.processes_to_xml (ps, options={ :indent => 2 })

    builder(options) do |xml|
      xml.processes(
        #:href => options[:self] || OpenWFE::href(options, :processes),
        :count => ps.size
      ) do

        rep_insert_links(ps, options, xml, OpenWFE::ProcessStatus)

        ps.each do |fei, process_status|
          process_to_xml(process_status, options)
        end
      end
    end
  end

  def Xml.process_to_xml (p, options={ :indent => 2 })

    builder(options) do |xml|

      xml.process do

        rep_insert_links(p, options, xml)

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

        xml.active_expressions(:count => p.expressions.size) do

          rep_insert_links(
            p.expressions, options, xml, OpenWFE::FlowExpression)

          p.expressions.each do |fexp|

            rep_insert_links(fexp, options, xml)

            fei = fexp.fei

            xml.expression(fei.to_s, :short => fei.to_web_s)
          end
        end

        xml.errors(:count => p.errors.size) do

          rep_insert_links(p.errors, options, xml)

          p.errors.each do |k, v|
            xml.error do

              rep_insert_links(v, options, xml)

              #xml.stacktrace do
              #  xml.cdata! "\n#{v.stacktrace}\n"
              #end
              xml.fei v.fei.to_s
              xml.message v.stacktrace.split("\n")[0]
            end
          end
        end

        tree = p.all_expressions.tree
        tree = tree.respond_to?(:to_json) ? tree.to_json : tree.inspect

        xml.tree(tree)
      end
    end
  end

  #
  # Turns a serie of process [status] instances into a hash.
  #
  def Json.processes_to_h (pss, opts={})

    h = { 'elements' =>  pss.values.collect { |ps| process_to_h(wi, opts) } }

    rep_insert_links(pss, opts, h, OpenWFE::ProcessStatus)
  end

  #
  # Turns a process [status] into a JSON string.
  #
  def Json.process_to_h (p, opts={})

    h = rep_insert_links(p, opts, {})

    %w{
      wfid wfname wfrevision launch_time paused timestamp branches
    }.inject(h) { |r, m|
      r[m] = p.send(m).to_s; r
    }

    %w{
      tags variables
    }.inject(h) { |r, m|
      r[m] = p.send(m); r
    }

    h['scheduled_jobs'] = p.scheduled_jobs.collect { |job|
      {
        'type' => job.class.name,
        'schedule_info' => job.schedule_info,
        'next_time' => job.next_time.to_s,
        'tags' => job.tags
      }
    }

    h['active_expressions'] = rep_insert_links(
      p.expressions, opts, {}, OpenWFE::FlowExpression)
    h['active_expressions']['elements'] = p.expressions.collect { |fexp|
      rep_insert_links(fexp, opts, { 'fei' => fexp.fei.to_s })
    }

    h['errors'] = rep_insert_links(
      p.errors, opts, {}, OpenWFE::ProcessError)
    h['errors']['elements'] = p.expressions.collect { |k, err|
      rep_insert_links(err, opts, {
        'fei' => err.fei.to_s,
        'message' => err.stacktrace.split("\n").first
      })
    }

    tree = p.all_expressions.tree
    tree = tree.respond_to?(:to_json) ? tree.to_json : tree.inspect
    h['tree'] = tree

    h
  end

  #--
  # nothing about from json (not needed for now)
  #++
end

