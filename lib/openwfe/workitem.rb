#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/utils'


module OpenWFE

  #
  # The convention for the result of some expressions is to store
  # their result in a workitem field named "__result__".
  #
  FIELD_RESULT = '__result__'

  #--
  # WORKITEMS
  #++

  #
  # The base class for all the workitems.
  #
  class WorkItem

    attr_accessor :last_modified, :attributes

    def initialize
      @last_modified = nil
      @attributes = {}
    end

    alias :fields :attributes
    alias :fields= :attributes=

    #
    # Sets the last_modified field to now
    #
    def touch

      @last_modified = Time.now
    end

    def to_h
      {
        'type' => self.class.name,
        'last_modified' => @last_modified,
        'attributes' => @attributes.clone
      }
    end

    def self.from_h (h)

      klass = WI_CLASSES[h['type']] || self
      wi = klass.new
      wi.last_modified = h['last_modified']
      wi.attributes = h['attributes'] || h['fields'] || {}
      wi
    end

    #
    # A shortcut for
    #
    #   workitem.attributes['key']
    #
    # is
    #
    #   workitem['key']
    #
    # (Note that
    #
    #   workitem.key
    #
    # will raise an exception if there is no attribute key).
    #
    def [] (key)

      @attributes[key]
    end

    #
    # A shortcut for
    #
    #   workitem.attributes['key'] = value
    #
    # is
    #
    #   workitem['key'] = value
    #
    def []= (key, value)

      @attributes[key] = value
    end

    #
    # In order to simplify code like :
    #
    #  value = workitem.attributes['xyz']
    #
    # to
    #
    #  value = workitem.xyz
    #
    # or
    #
    #  value = workitem['xyz']
    #
    # we overrode method_missing.
    #
    #  workitem.xyz = "my new value"
    #
    # is also possible
    #
    def method_missing (m, *args)

      method_name = m.to_s

      if args.length == 0
        value = @attributes[method_name]
        return value if value != nil
        raise "Missing attribute '#{method_name}' in workitem"
      end

      if args.length == 1 and method_name[-1, 1] == '='
        return @attributes[method_name[0..-2]] = args[0]
      end

      super(m, args)
    end

    #
    # Produces a deep copy of the workitem
    #
    def dup
      OpenWFE::fulldup(self)
    end

    #
    # A smarter alternative to
    #
    #   value = workitem.attributes[x]
    #
    # Via this method, nested values can be reached. For example :
    #
    #   wi = InFlowWorkItem.new()
    #   wi.attributes = {
    #     "field0" => "value0",
    #     "field1" => [ 0, 1, 2, 3, [ "a", "b", "c" ]],
    #     "field2" => {
    #       "a" => "AA",
    #       "b" => "BB",
    #       "c" => [ "C0", "C1", "C3" ]
    #     },
    #     "field3" => 3,
    #     "field99" => nil
    #   }
    #
    # will verify the following assertions :
    #
    #   assert wi.lookup_attribute("field3") == 3
    #   assert wi.lookup_attribute("field1.1") == 1
    #   assert wi.lookup_attribute("field1.4.1") == "b"
    #   assert wi.lookup_attribute("field2.c.1") == "C1"
    #
    def lookup_attribute (key)
      OpenWFE.lookup_attribute(@attributes, key)
    end

    #
    # The partner to the lookup_attribute() method. Behaves like it.
    #
    def has_attribute? (key)
      OpenWFE.has_attribute?(@attributes, key)
    end

    #
    # set_attribute() accomodates itself with nested key constructs.
    #
    def set_attribute (key, value)
      OpenWFE.set_attribute(@attributes, key, value)
    end

    #
    # unset_attribute() accomodates itself with nested key constructs.
    #
    def unset_attribute (key)
      OpenWFE.unset_attribute(@attributes, key)
    end

    alias :lookup_field :lookup_attribute
    alias :has_field? :has_attribute?
    alias :set_field :set_attribute
    alias :unset_field :unset_attribute

  end

  #
  # The common parent class for InFlowWorkItem and CancelItem.
  #
  class InFlowItem < WorkItem

    attr_accessor :flow_expression_id, :participant_name

    def last_expression_id
      @flow_expression_id
    end

    def last_expression_id= (fei)
      @flow_expression_id = fei
    end

    #
    # Just a handy alias for flow_expression_id
    #
    alias :fei :flow_expression_id
    alias :fei= :flow_expression_id=

    def to_h
      h = super
      h['flow_expression_id'] = @flow_expression_id.to_h
      h['participant_name'] = @participant_name
      h
    end

    def InFlowItem.from_h (h)
      wi = super
      wi.flow_expression_id = FlowExpressionId.from_h(h['flow_expression_id'])
      wi.participant_name = h['participant_name']
      wi
    end
  end

  #
  # When the term 'workitem' is used it's generally referring to instances
  # of this InFlowWorkItem class.
  # InFlowWorkItem are circulating within process instances and carrying
  # data around. Their 'payload' is located in their attribute Hash field.
  #
  class InFlowWorkItem < InFlowItem

    attr_accessor :dispatch_time

    #
    # in some contexts (ruote-rest, ruote-web2, the web...) workitems
    # have an URI
    #
    attr_accessor :uri

    #
    # In OpenWFEja, workitem history was stored, OpenWFEru doesn't do
    # it (no need to copy history over and over).
    #
    # (deprecated)
    #
    attr_accessor :history

    attr_accessor :store
      #
      # special : added by the ruby lib, not given by the worklist

    #
    # sets the filter for this workitem
    #
    def filter= (f)

      f ? @attributes['__filter__'] = f : @attributes.delete('__filter__')
    end

    #
    # returns the filter for this workitem
    #
    def filter

      @attributes['__filter__']
    end

    #
    # Returns the current timeout for the workitem (or nil if none is set).
    #
    # The result is an array [
    #   exp_class_name, exp_name, timestamp, timeout_duration, timeout_point ]
    #
    # 'timestamp' and 'timeout_point' are Float instances (use Time.at(f) to
    # turn into local Time instances)
    #
    def current_timeout

      stamps = self.attributes['__timeouts__']
      return nil unless stamps

      stamps["#{fei.wfid}__#{fei.expid}"]
    end

    #
    # Outputting the workitem in a human readable format
    #
    def to_s

      s =  "  #{self.class} :\n"
      s << "  - flow_expression_id : #{@flow_expression_id}\n"
      s << "  - participant_name :   #{@participant_name}\n"
      s << "  - last_modified :    #{@last_modified}\n"
      s << "  - dispatch_time :    #{@dispatch_time}\n"
      s << "  - attributes :\n"

      s << '  {\n'
      @attributes.keys.sort.each do |k|
        s << "    #{k.inspect} => #{@attributes[k].inspect},\n"
      end
      s << '  }'
      s
    end

    #
    # For some easy YAML encoding, turns the workitem into a Hash
    # (Any YAML-enabled platform can thus read it).
    #
    def to_h

      h = super
      h['dispatch_time'] = @dispatch_time
      h['attributes']['__filter__'] &&= filter.to_h
      h
    end

    #
    # Rebuilds an InFlowWorkItem from its hash version.
    #
    def self.from_h (h)

      wi = super(h)
      wi.filter &&= OpenWFE::FilterDefinition.from_h(wi.filter)
      wi
    end

    #
    # Returns a String containing the XML representation of this workitem.
    #
    def to_xml (options={ :indent => 2 })

      OpenWFE::Xml.workitem_to_xml(self, options)
    end

    #
    # Reads a String or a REXML document or element and returns a copy of the
    # InFlowWorkitem it represents.
    #
    def self.from_xml (xml)

      OpenWFE::Xml.workitem_from_xml(xml)
    end

    #
    # Sets the '__result__' field of this workitem
    #
    def set_result (result)

      @attributes[FIELD_RESULT] = result
    end

    #
    # Makes sure the '__result__' field of this workitem is empty.
    #
    def unset_result

      @attributes.delete(FIELD_RESULT)
    end

    #
    # Just a shortcut (for consistency) of
    #
    #   workitem.attributes["__result__"]
    #
    def get_result

      @attributes[FIELD_RESULT]
    end

    #
    # Returns true or false.
    #
    def get_boolean_result

      r = get_result
      return false unless r
      (r == true or r == 'true')
    end
  end

  #
  # When it needs to cancel a branch of a process instance, the engine
  # emits a CancelItem towards it.
  # It's especially important for participants to react correctly upon
  # receiving a cancel item.
  #
  class CancelItem < InFlowItem

    def initialize (workitem)

      super()
      @flow_expression_id = workitem.fei.dup
    end
  end

  #
  # LaunchItem instances are used to instantiate and launch processes.
  # They contain attributes that are used as the initial payload of the
  # workitem circulating in the process instances.
  #
  class LaunchItem < WorkItem

    DEF = '__definition'
    FIELD_DEF = "field:#{DEF}"

    attr_accessor :workflow_definition_url
      #, :description_map

    alias :wfdurl :workflow_definition_url
    alias :wfdurl= :workflow_definition_url=

    alias :definition_url :workflow_definition_url
    alias :definition_url= :workflow_definition_url=

    #
    # This constructor will build an empty LaunchItem.
    #
    # If the optional parameter process_definition is set, the
    # definition will be embedded in the launchitem attributes
    # for retrieval by the engine.
    #
    # There are several ways to specify the process definition.
    # Here are some examples:
    #
    #   # Use a Ruby class that extends OpenWFE::ProcessDefinition
    #   LaunchItem.new(MyProcessDefinition)
    #
    #   # Provide an XML process definition as a string
    #   definition = """
    #   <process-definition name="x" revision="y">
    #     <sequence>
    #       <participant ref="alpha" />
    #       <participant ref="bravo" />
    #     </sequence>
    #   </process-definition>
    #   """.strip
    #   LaunchItem.new(definition)
    #
    #   # Load an XML process definition from a local file
    #   require 'uri'
    #   LaunchItem.new(URI.parse("file:///tmp/my_process_definition.xml"))
    #
    #   # If you initialized your engine with
    #   # {:remote_definitions_allowed => true}, then you can also load an
    #   # XML process definition from a remote url
    #   require 'uri'
    #   LaunchItem.new(URI.parse("http://foo.bar/my_process_definition.xml"))
    #
    def initialize (process_definition=nil)

      super()

      self.definition = process_definition
    end

    def definition
      @attributes[DEF]
    end

    def definition= (process_definition)
      if process_definition
        @attributes[DEF] = process_definition
      else
        @attributes.delete(DEF)
      end
    end

    #
    # Turns the LaunchItem instance into a simple 'hash' (easily
    # serializable to other formats).
    #
    def to_h

      h = super
      h['workflow_definition_url'] = @workflow_definition_url
      h
    end

    #
    # Turns a hash into a LaunchItem instance.
    #
    def self.from_h (h)

      li = super

      li.definition_url =
        h['workflow_definition_url'] ||
        h['definition_url'] ||
        h['pdef_url']
      li.definition =
        h['workflow_definition'] ||
        h['definition'] ||
        h['pdef'] ||
        h['attributes']['__definition']

      li
    end
  end

  #
  # Turns a hash into its corresponding workitem (InFlowWorkItem, CancelItem,
  # LaunchItem).
  #
  def self.workitem_from_h (h)

    wi_class = WI_CLASSES[h['type']]
    wi_class.from_h(h)
  end

  WI_CLASSES = [
    OpenWFE::LaunchItem, OpenWFE::InFlowWorkItem, OpenWFE::CancelItem
  ].inject({}) { |r, c| r[c.to_s] = c; r }

end

