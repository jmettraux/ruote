#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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

    def initialize (h)

      @h = h
      class << @h; include Ruote::HashDot; end

      #class << @h['fields']
      #  alias_method :__get, :[]
      #  alias_method :__set, :[]=
      #  def [] (key)
      #    __get(key.to_s)
      #  end
      #  def []= (key, value)
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

      FlowExpressionId.new(h.fei)
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

    # Returns the payload, ie the fields hash.
    #
    def fields

      @h['fields']
    end

    # Sets all the fields in one sweep.
    #
    # Remember : the fields must be a JSONifiable hash.
    #
    def fields= (fields)

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
    def result= (r)

      fields['__result__'] = r
    end

    # When was this workitem dispatched ?
    #
    def dispatch_at

      fields['dispatched_at']
    end

    # Warning : equality is based on fei and not on payload !
    #
    def == (other)

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
    def lookup (key, container_lookup=false)

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
    def set_field (key, value)

      Ruote.set(@h['fields'], key, value)
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

      @h['fields']['params']
    end
  end
end

