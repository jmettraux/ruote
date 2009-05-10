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


require 'openwfe/workitem'
require 'openwfe/expool/errorjournal'
require 'openwfe/engine/status_methods'
require 'openwfe/expressions/flowexpression'
require 'openwfe/util/xml'
require 'openwfe/util/json'


module OpenWFE

  # Swaps from dots to underscores
  #
  #   swapdots "0_0_1" # => "0.0.1"
  #   swapdots "0.0.1" # => "0_0_1"
  #
  # DEPRECATED since 0.9.21
  #
  def self.swapdots (s)
    s.index('.') ? s.gsub(/\./, '_') : s.gsub(/\_/, '.')
  end

  def self.to_dots (s)
    s.gsub(/\_/, '.')
  end
  def self.to_uscores (s)
    s.gsub(/\./, '_')
  end

  #
  # a 'plain' implementation of a link generator
  #
  # TODO : what about inserting service links (main menu) ?
  #
  class PlainLinkGenerator

    def links (item, hint)

      #p [ 0, item.class, hint ]

      key_class = item.class
      content = if item.respond_to?(:first)
        item.first
      elsif item.respond_to?(:values)
        item.values.first
      end

      content_class = content ? content.class : hint

      key_class = flatten_class(key_class)
      content_class = flatten_class(content_class)

      key_class = [ key_class, content_class ] if content_class

      #p [ 1, key_class, GENS[key_class] ]

      method = GENS[key_class] || (return [])

      send(method, item)
    end

    # Override me (message to ruote-rest and ruote-web2)
    #
    # (Warning : this method turns dots to underscores in the id)
    #
    def link (rel, res, opts={})

      id, opts = if opts.is_a?(Hash)
        [ opts.delete(:id), opts ]
      else
        [ opts, {} ]
      end

      href = "/#{res}"

      href = "#{href}/#{OpenWFE.to_uscores(id)}" if id

      href = "#{href}?#{opts.collect { |k, v| "#{k}=#{v}" }.join('&')}" \
        if opts.size > 0

      [ href, rel ]
    end

    # Calls link() and converts its result from array to hash
    # { 'href' => x, 'rel' => y }
    #
    def hlink (rel, res, id=nil)

      l = link(rel, res, id)
      { 'href' => l[0], 'rel' => l[1] }
    end

    def insert_links (item, options, target, hint)

      unless options[:no_links]

        links(item, hint).each do |href, rel|
          do_insert_link(target, options, href, rel)
        end
      end

      target
    end

    protected

    def do_insert_link (target, options, href, rel)

      atts = { 'href' => href, 'rel' => rel }

      if options[:builder] # target is xml
        target.link(atts)
      else # target is a Hash
        (target['links'] ||= []) << atts
      end

      target
    end

    def flatten_class (c)

      return c unless c.is_a?(Class)

      c.ancestors.each do |a|
        return a if [ Array, Hash, OpenWFE::FlowExpression ].include?(a)
      end

      return OpenWFE::ProcessError if c.to_s.downcase.match(/processerror/)
        # OpenWFE::Extras::ProcessError...

      return OpenWFE::InFlowWorkItem if c.to_s.downcase.match(/workitem/)
        # OpenWFE::Extras::Workitem...

      c
    end

    #
    # some kind of 'case'
    #
    GENS = {
      OpenWFE::InFlowWorkItem => 'workitem',
      [ Array, OpenWFE::InFlowWorkItem ] => 'workitems',
      OpenWFE::ProcessStatus => 'process',
      [ Array, OpenWFE::ProcessStatus ] => 'processes',
      [ Hash, OpenWFE::ProcessStatus ] => 'processes',
      OpenWFE::FlowExpression => 'expression',
      [ Array, OpenWFE::FlowExpression ] => 'expressions',
      #[ Hash, OpenWFE::FlowExpression ] => 'expressions',
      OpenWFE::ProcessError => 'error',
      [ Array, OpenWFE::ProcessError ] => 'errors',
      [ Hash, OpenWFE::ProcessError ] => 'errors',

      [ OpenWFE::FlowExpressionId, :environment ] => 'to_environment',
      [ OpenWFE::FlowExpressionId, :child ] => 'to_child',
      [ OpenWFE::FlowExpressionId, :parent ] => 'to_parent'
    }

    # generate the links for a given item
    #
    def gen_links (res, item, &block)

      if block # unique element

        [ link('via', res), link('self', res, block.call(item)) ]

      elsif item.respond_to?(:current_page) and item.total_pages > 1

        a = [
          link('via', ''),
          link('self', res, 'page' => item.current_page)
        ]
        a << link('prev', res, 'page' => item.current_page - 1) \
          if item.current_page > 1
        a << link('next', res, 'page' => item.current_page + 1) \
          if item.current_page < item.total_pages
        a

      else # collection

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
      #gen_links('errors', item) do |i|
      #  "#{i.fei.wfid}/#{i.fei.expid}/#{i.date.strftime("%Y%m%d%H%M%S")}"
      #end
      gen_links('errors', item) { |i| "#{i.fei.wfid}/#{i.fei.expid}" }
    end
    def errors (item)
      gen_links('errors', item)
    end

    # all about expressions...

    def expression_id (item)

      fei = item.fei

      e = (
        item.is_a?(OpenWFE::Environment) ||
        OpenWFE::Environment.expression_names.include?(fei.expname)
      ) ? 'e' : ''

      "#{fei.wfid}/#{fei.expid}#{e}"
    end

    def expression (item)
      gen_links('expressions', item) { |fexp| expression_id(fexp) }
    end
    def expressions (item)
      gen_links('expressions', item)
    end

    def to_environment (env)
      [ link('environment_expression', 'expressions', expression_id(env)) ]
    end
    def to_parent (par)
      [ link('parent_expression', 'expressions', expression_id(par)) ]
    end
    def to_child (child)
      [ link('child_expression', 'expressions', expression_id(child)) ]
    end
  end

  def self.rep_insert_link (item, options, target, rel_symbol)

    rep.insert_links(item, options, target, rel_symbol)
  end

  def self.rep_insert_links (item, options, target, hint=nil)

    lgen = options[:linkgen] || (return target)
    lgen = PlainLinkGenerator.new if lgen == :plain

    lgen.insert_links(item, options, target, hint)
  end

  # (don't use directly)
  #
  def Json.collection_to_h (col, opts, hint, &block)

    elts = col.collect(&block)

    return elts if opts[:nometa]

    OpenWFE.rep_insert_links(col, opts, { 'elements' => elts }, hint)
  end

  # (don't use directly)
  #
  def Xml.collection_to_xml (tag, col, opts, hint, &block)

    builder(opts) do |xml|

      xml.tag!(tag, :count => col.size) do

        OpenWFE.rep_insert_links(col, opts, xml, hint)

        col.each(&block)
      end
    end
  end

  def Json.collection_from_h (h, &block)

    h['elements'].collect { |e| block.call(e) }
  end

  def Xml.collection_from_xml (elt, childname, &block)

    elt.owfe_elt_children.select { |e|
      e.name == childname
    }.collect { |e|
      block.call(e)
    }
  end

  #--
  # launchitems
  #++

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

  # Turns a launchitem into a hash
  #
  def Json.launchitem_to_h (li)

    li.to_h
  end

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
          xml.tag!(f.to_s, fei.send(f))
        end

        xml.fei_short(fei.to_s)
          # a short, 1 string version of the fei
      end
    end
  end

  def Xml.fei_from_xml (xml)

    xml = to_element(xml, 'flow_expression_id')

    FlowExpressionId::FIELDS.inject(FlowExpressionId.new) do |fei, f|
      fei.send("#{f}=", text(xml, f.to_s)); fei
    end
  end

  #--
  # workitems
  #++

  # Turns an [InFlow]WorkItem into some XML.
  #
  def Xml.workitem_to_xml (wi, options={})

    wi = wi.to_owfe_workitem if wi.respond_to?(:to_owfe_workitem)

    builder(options) do |xml|

      xml.workitem do

        OpenWFE.rep_insert_links(wi, options, xml)

        fei_to_xml(wi.fei, options)

        xml.last_modified to_httpdate(wi.last_modified)

        xml.participant_name wi.participant_name

        xml.dispatch_time to_httpdate(wi.dispatch_time)
        xml.store wi.store

        xml.attributes do
          hash_to_xml wi.attributes, options
        end
      end
    end
  end

  # Turns a list of workitems into a XML document (String)
  #
  def Xml.workitems_to_xml (wis, options={})

    collection_to_xml(
      options[:tag] || 'workitems', wis, options, OpenWFE::InFlowWorkItem
    ) { |wi|
      workitem_to_xml(wi, options)
    }
  end

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

  # Extracts a list of workitems from some XML.
  #
  def Xml.workitems_from_xml (xml)

    Xml.collection_from_xml(to_element(xml, 'workitems'), 'workitem') do |elt|
      workitem_from_xml(elt)
    end
  end

  # Turns an array of workitems into a hash
  #
  def Json.workitems_to_h (wis, opts={})

    collection_to_h(wis, opts, OpenWFE::InFlowWorkItem) { |wi|
      workitem_to_h(wi, opts)
    }
  end

  # Turns a workitem into a hash
  #
  def Json.workitem_to_h (wi, opts={})

    wi = wi.to_owfe_workitem if wi.respond_to?(:to_owfe_workitem)

    OpenWFE.rep_insert_links(wi, opts, wi.to_h)
  end

  #--
  # cancelitems
  #
  #def Xml.cancelitem_to_xml (ci)
  #end
  #def Xml.cancelitem_from_xml (xml)
  #end
  #def Json.cancelitem_to_h (ci)
  #end
  #def Json.cancelitem_from_h (h)
  #end
  #++

  #--
  # processes (instances of ProcessStatus)
  #++

  def Xml.processes_to_xml (pss, options={ :indent => 2 })

    collection_to_xml(
      'processes', pss, options, OpenWFE::ProcessStatus
    ) { |fei, ps|
      ps = ps || fei # accomodating arrays and hashes
      process_to_xml(ps, options.merge(:short => true))
    }
  end

  def Xml.process_to_xml (pr, options={ :indent => 2 })

    builder(options) do |xml|

      xml.process do

        OpenWFE.rep_insert_links(pr, options, xml)

        xml.wfid pr.wfid
        xml.wfname pr.wfname
        xml.wfrevision pr.wfrevision

        xml.launch_time pr.launch_time
        xml.paused pr.paused

        xml.timestamp pr.timestamp.to_s

        xml.tags do
          pr.tags.each { |t| xml.tag t }
        end

        xml.branches pr.branches

        unless options[:short]

          hash_to_xml(
            pr.variables, options.merge(:tag => 'variables'))

          #workitems_to_xml(
          #  pr.applied_workitems, options.merge(:tag => 'applied_workitems'))
        end

        xml.applied_workitems :count => pr.applied_workitems.size

        xml.scheduled_jobs do
          pr.scheduled_jobs.each do |j|
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

        expressions_to_xml(pr.expressions, options.merge(:short => true))

        errors_to_xml(pr.errors, options.merge(:short => true))

        tree = pr.all_expressions.tree
        tree = tree.respond_to?(:to_json) ? tree.to_json : tree.inspect

        xml.tree(tree)
      end
    end
  end

  # Turns a serie of process [status] instances into a hash.
  #
  def Json.processes_to_h (pss, opts={})

    collection_to_h(pss, opts, OpenWFE::ProcessStatus) { |fei, ps|
      ps = ps || fei # accomodating arrays and hashes
      process_to_h(ps, opts.merge(:short => true))
    }
  end

  # Turns a process [status] into a JSON string.
  #
  def Json.process_to_h (pr, opts={})

    h = OpenWFE.rep_insert_links(pr, opts, {})

    %w{
      wfid wfname wfrevision launch_time paused timestamp branches
    }.inject(h) { |r, m|
      r[m] = pr.send(m).to_s; r
    }

    h['tags'] = pr.tags
    h['variables'] = pr.variables unless opts[:short]

    h['scheduled_jobs'] = pr.scheduled_jobs.collect { |job|
      {
        'type' => job.class.name,
        'schedule_info' => job.schedule_info,
        'next_time' => job.next_time.to_s,
        'tags' => job.tags
      }
    }

    h['expressions'] = expressions_to_h(
      pr.expressions, opts.merge(:short => true))

    h['applied_workitem_count'] = pr.applied_workitems.size

    h['errors'] = errors_to_h(
      pr.errors, opts.merge(:short => true))

    tree = pr.all_expressions.tree
    tree = tree.respond_to?(:to_json) ? tree.to_json : tree.inspect
    h['tree'] = tree

    h
  end

  #--
  # expressions
  #++

  def Xml.expressions_to_xml (exps, opts={})

    collection_to_xml('expressions', exps, opts, OpenWFE::FlowExpression) { |e|
      expression_to_xml(e, opts)
    }
  end

  def Xml.expression_to_xml (exp, opts={})

    builder(opts) do |xml|
      xml.expression do

        OpenWFE.rep_insert_links(exp, opts, xml)

        xml.fei exp.fei.to_s
        xml.name exp.fei.expname
        xml.tag! 'class', exp.class.name
        xml.apply_time OpenWFE::Xml.to_httpdate(exp.apply_time)

        unless opts[:short]

          OpenWFE.rep_insert_links(exp.parent_id, opts, xml, :parent)
          OpenWFE.rep_insert_links(exp.environment_id, opts, xml, :environment)
          (exp.children || []).each do |cfei|
            OpenWFE.rep_insert_links(cfei, opts, xml, :child)
          end

          rep = exp.raw_representation
          rep = rep.respond_to?(:to_json) ? rep.to_json : rep.inspect

          xml.raw rep
          xml.raw_updated(exp.raw_rep_updated == true)

          # TODO : variables ?
        end
      end
    end
  end

  def Json.expressions_to_h (exps, opts={})

    collection_to_h(exps, opts, OpenWFE::FlowExpression) { |e|
      expression_to_h(e, opts)
    }
  end

  def Json.expression_to_h (exp, opts={})

    h = OpenWFE.rep_insert_links(exp, opts, {})

    h['fei'] = exp.fei.to_s
    h['name'] = exp.fei.expname
    h['class'] = exp.class.to_s
    h['apply_time'] = exp.apply_time.to_s

    return h if opts[:short]

    OpenWFE.rep_insert_links(exp.parent_id, opts, h, :parent)
    OpenWFE.rep_insert_links(exp.environment_id, opts, h, :environment)
    (exp.children || []).each do |cfei|
      OpenWFE.rep_insert_links(cfei, opts, h, :child)
    end

    h['raw'] = exp.raw_representation
    h['raw_updated'] = (exp.raw_rep_updated == true)

    # TODO : variables ?

    h
  end

  #--
  # errors
  #++

  def Xml.errors_to_xml (errs, opts={})

    collection_to_xml('errors', errs, opts, OpenWFE::ProcessError) { |k, err|
      error_to_xml(err || k, opts)
    }
  end

  def Xml.error_to_xml (err, options={})

    err = err.as_owfe_error if err.respond_to?(:as_owfe_error)

    builder(options) do |xml|
      xml.error do

        OpenWFE.rep_insert_links(err, options, xml)

        xml.date err.date # when
        xml.fdate err.fdate
        xml.fei err.fei.to_s # what
        xml.call err.message.to_s # how
        xml.message err.stacktrace.split("\n")[0] # how

        unless options[:short]

          xml.wfid err.wfid
          xml.expid err.fei.expid
          #xml.stacktrace do
          #  xml.cdata! "\n#{v.stacktrace}\n"
          #end

          workitem_to_xml(err.workitem, options.merge(:no_links => true))
        end
      end
    end
  end

  def Json.errors_to_h (errs, opts={})

    collection_to_h(errs, opts, OpenWFE::ProcessError) { |k, err|
      error_to_h(err || k, opts)
    }
  end

  def Json.error_to_h (err, opts={})

    err = err.as_owfe_error if err.respond_to?(:as_owfe_error)

    h = {}
    h['date'] = err.date
    h['fdate'] = err.fdate
    h['fei'] = err.fei.to_s
    h['message'] = err.stacktrace.split("\n").first

    OpenWFE.rep_insert_links(err, opts, h)

    return h if opts[:short]

    h['wfid'] = err.wfid
    h['expid'] = err.fei.expid
    h['workitem'] = workitem_to_h(err.workitem, opts.merge(:no_links => true))
    h
  end

  def Xml.errors_from_xml (xml)

    Xml.collection_from_xml(to_element(xml, 'errors'), 'error') do |elt|
      error_from_xml(elt)
    end
  end

  def Xml.error_from_xml (xml)

    root = to_element(xml, 'error')

    e = OpenWFE::ProcessError.new
    e.fei = OpenWFE::FlowExpressionId.from_s(text(root, 'fei'))
    e.date = text(root, 'date')
    e.message = text(root, 'call')
    e.stacktrace = text(root, 'message')

    e.fdate = text(root, 'fdate')
    e.fdate = e.fdate.to_f if e.fdate

    e.workitem = workitem_from_xml(root.owfe_first_elt_child('workitem'))

    e
  end

  def Json.errors_from_h (h)

    collection_from_h(h) { |e| error_from_h(e) }
  end

  def Json.error_from_h (h)

    e = OpenWFE::ProcessError.new
    e.fei = OpenWFE::FlowExpressionId.from_s(h['fei'])
    e.date = h['date']
    e.fdate = h['fdate']
    e.message = h['call']

    e.workitem = h['workitem']
    e.workitem = OpenWFE::InFlowWorkItem.from_h(e.workitem) if e.workitem
    e
  end
end

