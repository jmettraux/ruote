#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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


module Ruote

  #
  # An error class for validation errors gathered during filtering.
  #
  class ValidationError < StandardError

    attr_accessor :field, :value, :rule

    def initialize (rule, field, value)

      @rule = rule
      @value = value
      @field = field
      super("field '#{field}' doesn't follow rule #{rule.inspect}")
    end
  end

  # Given a filter (a list of rules) and a hash (probably workitem fields)
  # performs the validations / transformations dictated by the rules.
  #
  # See the Ruote::Exp::FilterExpression for more information.
  #
  def self.filter (filter, hash)

    #hash = Ruote.fulldup(hash)
    hash = Rufus::Json.dup(hash)
      # since Yajl is faster than Marshal...

    filter.each do |rule|

      field = rule['field'] || rule['f']
      value = Ruote.lookup(hash, field)

      valid = nil

      # basis

      if rule['remove'] || rule['rm']

        Ruote.unset(hash, field)

      elsif s = rule['set']

        Ruote.set(hash, field, Rufus::Json.dup(s))

      elsif ct = find(rule, %w[ copy cp move mv ], 'to')

        Ruote.set(hash, ct, Rufus::Json.dup(value))
        Ruote.unset(hash, field) if rule['move_to'] || rule['mv_to']

      elsif cf = find(rule, %w[ copy cp move mv ], 'from')

        Ruote.set(hash, field, Rufus::Json.dup(Ruote.lookup(hash, cf)))
        Ruote.unset(hash, cf) if rule['move_from'] || rule['mv_from']

      elsif sz = rule['size'] || rule['sz']

        sz = sz.is_a?(String) ?
          sz.split(',').collect { |i| i.to_i } : Array(sz)

        valid = if value.respond_to?(:size)
          (sz.first ? value.size >= sz.first : true) and
          (sz.last ? value.size <= sz.last : true)
        else
          false
        end

      elsif t = rule['type'] || rule['t']

        valid = enforce_type(t, field, value)

      elsif m = rule['match'] || rule['m']

        valid = value.nil? ? false : value.to_s.match(m) != nil

      elsif s = rule['smatch'] || rule['sm']

        valid = value.is_a?(String) ? value.match(s) != nil : false
      end

      # dealing with :and and :or...

      if valid == false

        if o = rule['or']
          Ruote.set(hash, field, Rufus::Json.dup(o))
        elsif rule['and'].nil?
          raise ValidationError.new(rule, field, value)
        end

      elsif valid == true and a = rule['and']

        Ruote.set(hash, field, Rufus::Json.dup(a))

      elsif valid == nil and value.nil? and o = (rule['or'] || rule['default'])

        Ruote.set(hash, field, Rufus::Json.dup(o))
      end
    end

    hash
  end

  # :nodoc:
  NUMBER_CLASSES = [ Fixnum, Float ]

  # :nodoc:
  BOOLEAN_CLASSES = [ TrueClass, FalseClass ]

  # :nodoc:
  #
  # a helper method for .filter
  #
  def self.enforce_type (type, field, value)

    types = type.is_a?(Array) ? type : type.split(',')

    valid = false

    types.each do |t|

      valid = valid || case t.strip
        when 'null', 'nil'
          value == nil
        when 'string'
          value.class == String
        when 'number'
          NUMBER_CLASSES.include?(value.class)
        when 'object', 'hash'
          value.class == Hash
        when 'array'
          value.class == Array
        when 'boolean', 'bool'
          BOOLEAN_CLASSES.include?(value.class)
        else
          raise ArgumentError.new("unknown type '#{t}'")
      end
    end

    # TODO : Array<x> and Object<y>

    valid
  end

  # :nodoc:
  #
  # a helper method for .filter
  #
  def self.find (rule, verbs, direction)

    verbs.each do |verb|

      value = rule["#{verb}_#{direction}"]
      return value if value
    end

    nil
  end
end

