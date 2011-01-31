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

  class ValidationError < StandardError

    attr_accessor :field, :value, :rule

    def initialize (field, value, rule)

      @field = field
      @value = value
      @rule = rule
      super("field '#{field}' doesn't follow rule #{rule.inspect}")
    end
  end

  def self.filter (filter, hash)

    #hash = Ruote.fulldup(hash)
    hash = Rufus::Json.dup(hash)
      # since Yajl is faster than Marshal...

    filter.each do |rule|

      field = rule['field']
      value = Ruote.lookup(hash, field)

      if rule['remove']
        Ruote.unset(hash, rule['field'])

      elsif d = rule['default'] and value.nil?

        Ruote.set(hash, rule['field'], Rufus::Json.dup(d))

      elsif rule['type']

        enforce_type(rule, field, value)

      #elsif m = rule['match']
      #elsif o = rule['or']
      end
    end

    hash
  end

  NUMBER_CLASSES = [ Fixnum, Float ]
  BOOLEAN_CLASSES = [ TrueClass, FalseClass ]

  def self.enforce_type (rule, field, value)

    types = rule['type']
    types = types.is_a?(Array) ? types : types.split(',')

    valid = false

    types.each do |type|

      valid = valid || case type.strip
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
          raise ArgumentError.new("unknown type '#{rule['type']}'")
      end
    end

    # TODO : Array<x> and Object<y>

    raise ValidationError.new(rule, field, value) unless valid
  end
end

