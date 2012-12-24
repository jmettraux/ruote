#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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

require 'ruote/util/misc'
require 'ruote/util/lookup'
require 'ruote/util/hashdot'


module Ruote

  #
  # A workitem can be thought of an "execution token", but with a payload
  # (fields).
  #
  # The payload/fields MUST be JSONifiable.
  #
  class Workitem

    attr_reader :h

    def initialize(h)

      @h = h
      class << @h; include Ruote::HashDot; end

      #class << @h['fields']
      #  alias_method :__get, :[]
      #  alias_method :__set, :[]=
      #  def [](key)
      #    __get(key.to_s)
      #  end
      #  def []=(key, value)
      #    __set(key.to_s, value)
      #  end
      #end
        # indifferent access, not activated for now
    end

    # Returns the underlying Hash instance.
    #
    def to_h

      @h
    end

    # Returns the String id for this workitem (something like
    # "0_0!!20100507-wagamama").
    #
    # It's in fact a shortcut for
    #
    #   Ruote::FlowExpressionId.to_storage_id(h.fei)
    #
    def sid

      Ruote::FlowExpressionId.to_storage_id(h.fei)
    end

    # Returns the "workflow instance id" (unique process instance id) of
    # the process instance which issued this workitem.
    #
    def wfid

      h.fei['wfid']
    end

    # Returns a Ruote::FlowExpressionId instance.
    #
    def fei

      FlowExpressionId.new(@h['fei'])
    end

    # Returns a complete copy of this workitem.
    #
    def dup

      Workitem.new(Rufus::Json.dup(@h))
    end

    # The participant for which this item is destined. Will be nil when
    # the workitem is transiting inside of its process instance (as opposed
    # to when it's being delivered outside of the engine).
    #
    def participant_name

      @h['participant_name']
    end

    # Returns the name of the workflow to which this workitem belongs, or nil.
    #
    def wf_name; @h['wf_name']; end

    # Returns the revision of the workflow to which this workitem belongs,
    # or nil.
    #
    def wf_revision; @h['wf_revision']; end

    # Returns the UTC time string indicating when the workflow was launched.
    #
    def wf_launched_at; @h['wf_launched_at']; end

    alias launched_at wf_launched_at
    alias definition_name wf_name
    alias definition_revision wf_revision

    # Returns the name of the sub-workflow the workitem is currently in.
    # (If it's in the main flow, it will return the name of the main flow,
    # if that flow has a name...)
    #
    def sub_wf_name; @h['sub_wf_name']; end

    # The equivalent of #sub_wf_name for revisions.
    #
    def sub_wf_revision; @h['sub_wf_revision']; end

    # Returns the UTC time string indicating when the sub-workflow was launched.
    #
    def sub_wf_launched_at; @h['sub_wf_launched_at']; end

    # Used by some participants, returns the "owner" of the workitem. Mostly
    # used when reserving workitems.
    #
    def owner

      @h['owner']
    end

    # Returns the payload, ie the fields hash.
    #
    def fields

      @h['fields']
    end

    # Sets all the fields in one sweep.
    #
    # Remember : the fields must be a JSONifiable hash.
    #
    def fields=(fields)

      @h['fields'] = fields
    end

    # A shortcut to the value in the field named __result__
    #
    # This field is used by the if expression for instance to determine
    # if it should branch to its 'then' or its 'else'.
    #
    def result

      fields['__result__']
    end

    # Sets the value of the 'special' field __result__
    #
    # See #result
    #
    def result=(r)

      fields['__result__'] = r
    end

    # When was this workitem dispatched ?
    #
    def dispatched_at

      fields['dispatched_at']
    end

    # Warning : equality is based on fei and not on payload !
    #
    def ==(other)

      return false if other.class != self.class
      self.h['fei'] == other.h['fei']
    end

    alias eql? ==

    # Warning : hash is fei's hash.
    #
    def hash

      self.h['fei'].hash
    end

    # For a simple key
    #
    #   workitem.lookup('toto')
    #
    # is equivalent to
    #
    #   workitem.fields['toto']
    #
    # but for a complex key
    #
    #   workitem.lookup('toto.address')
    #
    # is equivalent to
    #
    #   workitem.fields['toto']['address']
    #
    def lookup(key, container_lookup=false)

      Ruote.lookup(@h['fields'], key, container_lookup)
    end

    # 'lf' for 'lookup field'
    #
    alias :lf :lookup

    # Like #lookup allows for nested lookups, #set_field can be used
    # to set sub fields directly.
    #
    #   workitem.set_field('customer.address.city', 'Pleasantville')
    #
    # Warning : if the customer and address field and subfield are not present
    # or are not hashes, set_field will simply create a "customer.address.city"
    # field and set its value to "Pleasantville".
    #
    def set_field(key, value)

      Ruote.set(@h['fields'], key, value)
    end

    # Shortcut for #lookup(key)
    #
    #   workitem.fields['customer']['city']
    #     # or
    #   workitem.lookup('customer.city')
    #     # or
    #   workitem['customer.city']
    #
    def [](key)

      lookup(key.to_s)
    end

    # Shortcut for #set_field(key, value)
    #
    #   workitem.fields['customer']['city'] = 'Toronto'
    #     # or
    #   workitem.set_field('customer.city', 'Toronto')
    #     # or
    #   workitem['customer.city'] = 'Toronto'
    #
    def []=(key, value)

      set_field(key.to_s, value)
    end

    # Shortcut for wi.fields['__timed_out__']
    #
    def timed_out

      @h['fields']['__timed_out__']
    end

    # Shortcut for wi.fields['__error__']
    #
    def error

      @h['fields']['__error__']
    end

    # Shortcut for wi.fields['params']
    #
    # When a participant is invoked like in
    #
    #    participant :ref => 'toto', :task => 'x"
    #
    # then
    #
    #    p workitem.params
    #      # => { 'ref' => 'toto', 'task' => 'x' }
    #
    def params

      @h['fields']['params'] || {}
    end

    # When a participant is invoked like in
    #
    #    accounting 'do_invoice', :customer => 'acme corp'
    #
    # then
    #
    #    p workitem.params
    #      # => { 'ref' => 'accounting', 'do_invoice' => nil, 'customer' => 'acme corp' }
    #
    # and
    #
    #    p workitem.param_text
    #      # => 'do_invoice'
    #
    # It returns nil when there is no text passed directly.
    #
    def param_text

      (params.find { |k, v| v.nil? } || []).first
    end

    # Sometimes a value is passed as a[n expression] parameter or as a
    # workitem field, with priority to the parameter.
    #
    #   sequence do
    #     set 'f:country' => 'uruguay'
    #     participant 'toto'
    #       # in toto, workitem.param_or_field(:country) will yield 'uruguay'
    #     participant 'toto', :country => 'argentina'
    #       # workitem.param_or_field(:country) will yield 'argentina'
    #   end
    #
    def param_or_field(key)

      key = key.to_s

      (@h['fields']['params'] || {})[key] || @h['fields'][key]
    end

    # Like #param_or_field, but priority is given to the field.
    #
    def field_or_param(key)

      key = key.to_s

      @h['fields'][key] || (@h['fields']['params'] || {})[key]
    end

    # Shortcut to the temporary/trailing fields
    #
    # http://groups.google.com/group/openwferu-users/browse_thread/thread/981dba6204f31ccc
    #
    def t
      @h['fields']['t'] ||= {}
    end

    # (advanced)
    #
    # Shortcut for wi.fields['__command__']
    #
    # __command__ is read by the 'cursor' and the 'iterator' expressions
    # when a workitem reaches it (apply and reply).
    #
    def command

      @h['fields']['__command__']
    end

    # (advanced)
    #
    # Shortcut for wi.fields['__command__'] = x
    #
    # __command__ is read by the 'cursor' and the 'iterator' expressions
    # when a workitem reaches it (apply and reply).
    #
    def command=(com)

      com = com.is_a?(Array) ? com : com.split(' ')
      com = [ com.first, com.last ]
      com[1] = com[1].to_i if com[1] and com[0] != 'jump'

      @h['fields']['__command__'] = com
    end

    # Shortcut for wi.fields['__tags__']
    #
    def tags

      @h['fields']['__tags__'] || []
    end

    # How many times was this workitem re_dispatched ?
    #
    # It's used by LocalParticipant re_dispatch mostly, or by participant
    # which poll a resource and re_dispatch after a while.
    #
    def re_dispatch_count

      @h['re_dispatch_count'] || 0
    end

    # Encodes this workitem as JSON. If pretty is set to true, will output
    # prettified JSON.
    #
    def as_json(pretty=false)

      pretty ? Rufus::Json.pretty_encode(@h) : Rufus::Json.encode(@h)
    end

    # Given a JSON String, decodes and returns a Ruote::Workitem instance.3
    # If the decode thing is not an object/hash, will raise an ArgumentError.
    #
    def self.from_json(json)

      h = Rufus::Json.decode(json)

      raise ArgumentError(
        "Arg not a JSON hash/object, but a #{h.class}. Cannot create workitem"
      ) unless h.is_a?(Hash)

      self.new(h)
    end

    protected

    # Used by FlowExpression when entering a tag.
    #
    def add_tag(tag)

      (@h['fields']['__tags__'] ||= []) << tag
    end

    # Used by FlowExpression when leaving a tag.
    #
    def remove_tag(tag)

      # it's a bit convoluted... trying to cope with potential inconsistencies
      #
      # normally, it should only be a tags.pop(), but since user have
      # access to the workitem and its fields... better be safe than sorry

      tags = (@h['fields']['__tags__'] || [])

      if index = tags.rindex(tag)
        tags.delete_at(index)
      end

      @h['fields']['__left_tag__'] = tag
    end
  end
end

