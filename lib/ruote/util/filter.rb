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

    attr_reader :deviations

    def initialize(deviations)
      @deviations = deviations
      super("validation failed with #{@deviations.size} deviation(s)")
    end
  end

  # Given a filter (a list of rules) and a hash (probably workitem fields)
  # performs the validations / transformations dictated by the rules.
  #
  # See the Ruote::Exp::FilterExpression for more information.
  #
  def self.filter(filter, hash, double_caret=nil)

    hash = Rufus::Json.dup(hash)

    hash['^'] = Rufus::Json.dup(hash)
    hash['^^'] = double_caret ? Rufus::Json.dup(double_caret) : hash['^']
      # the 'originals'

    deviations = filter.collect { |rule|
      RuleSession.new(hash, rule).run
    }.compact

    hash.delete('^')
    hash.delete('^^')
      # remove the 'originals'

    raise ValidationError.new(deviations) unless deviations.empty?

    hash
  end

  # :nodoc:
  #
  # The class used to run a rule (a line of a filter).
  #
  class RuleSession

    SKIP = %w[ and or field ]
    NUMBER_CLASSES = [ Fixnum, Float ]
    BOOLEAN_CLASSES = [ TrueClass, FalseClass ]

    def initialize(hash, rule)

      @hash = hash
      @rule = rule
      @field = rule['field'] || rule['f']
      @value = Ruote.lookup(hash, @field)
      @valid = nil
    end

    def run

      @rule.each do |k, v|

        next if SKIP.include?(k)

        m = "_#{k}"
        next unless self.respond_to?(m)

        self.send(m, k, v)
      end

      raise_or
    end

    protected

    def _remove(m, v)

      Ruote.unset(@hash, @field)
    end
    alias _rm _remove

    def _set(m, v)

      Ruote.set(@hash, @field, Rufus::Json.dup(v))
    end
    alias _s _set

    def _copy_to(m, v)

      Ruote.set(@hash, v, Rufus::Json.dup(@value))
      Ruote.unset(@hash, @field) if m == 'move_to' or m == 'mv_to'
    end
    alias _cp_to _copy_to
    alias _move_to _copy_to
    alias _mv_to _copy_to


    def _copy_from(m, v)

      Ruote.set(@hash, @field, Rufus::Json.dup(Ruote.lookup(@hash, v)))
      Ruote.unset(@hash, v) if m == 'move_from' or m == 'mv_from'
    end
    alias _cp_from _copy_from
    alias _move_from _copy_from
    alias _mv_from _copy_from

    def _merge_to(m, v)

      target = Ruote.lookup(@hash, v)

      return unless target.respond_to?(:merge!)

      target.merge!(Rufus::Json.dup(@value))
      target.delete('^')
      target.delete('^^')
      Ruote.unset(@hash, @field) if m == 'migrate_to' or m == 'mi_to'
    end
    alias _mg_to _merge_to
    alias _migrate_to _merge_to
    alias _mi_to _merge_to

    def _merge_from(m, v)

      return unless @value.respond_to?(:merge!)

      @value.merge!(Rufus::Json.dup(Ruote.lookup(@hash, v)))
      @value.delete('^')
      @value.delete('^^')

      if v != '.' and (m == 'migrate_from' or m == 'mi_from')
        Ruote.unset(@hash, v)
      end
    end
    alias _mg_from _merge_from
    alias _migrate_from _merge_from
    alias _mi_from _merge_from

    def _size(m, v)

      v = v.is_a?(String) ? v.split(',').collect { |i| i.to_i } : Array(v)

      validate(if @value.respond_to?(:size)
        (v.first ? @value.size >= v.first : true) and
        (v.last ? @value.size <= v.last : true)
      else
        false
      end)
    end
    alias _sz _size

    def _empty(m, v)

      validate(@value.respond_to?(:empty?) ? @value.empty? : false)
    end
    alias _e _empty

    def _in(m, v)

      v = v.is_a?(Array) ? v : v.to_s.split(',').collect { |e| e.strip }
      validate(v.include?(@value))
    end
    alias _i _in

    def _has(m, v)

      v = v.is_a?(Array) ? v : v.to_s.split(',').collect { |e| e.strip }

      validate(if @value.is_a?(Hash)
        (@value.keys & v) == v
      elsif @value.is_a?(Array)
        (@value & v) == v
      else
        false
      end)
    end
    alias _h _has

    def _type(m, v)

      validate(of_type?(@value, v))
    end
    alias _t _type

    TYPE_SPLITTER = /^(?: *, *)?([^,<]+(?:<.+>)?)(.*)$/

    def split_type(type)

      result = []

      loop do
        m = TYPE_SPLITTER.match(type)
        break unless m
        result << m[1]
        type = m[2]
      end

      result
    end

    def of_type?(value, types)

      types = types.is_a?(Array) ? types : split_type(types)

      valid = false

      types.each do |type|

        valid ||= case type
          when 'null', 'nil'
            value == nil
          when 'string'
            value.class == String
          when 'number'
            NUMBER_CLASSES.include?(value.class)
          when /^(array|object|hash)<(.*)>$/
            children_of_type?(value, $~[2])
          when 'object', 'hash'
            value.class == Hash
          when 'array'
            value.class == Array
          when 'boolean', 'bool'
            BOOLEAN_CLASSES.include?(value.class)
          else
            raise ArgumentError.new("unknown type '#{type}'")
        end
      end

      valid
    end

    def children_of_type?(values, types)

      return false unless values.is_a?(Array) or values.is_a?(Hash)

      values = values.is_a?(Array) ? values : values.values

      values.each { |v| of_type?(v, types) or return(false) }

      true
    end

    def _match(m, v)

      validate(@value.nil? ? false : @value.to_s.match(v) != nil)
    end
    alias _m _match

    def _smatch(m, v)

      validate(@value.is_a?(String) ? @value.match(v) != nil : false)
    end
    alias _sm _smatch

    def _valid(m, v)

      validate(v.to_s == 'true')
    end
    alias _v _valid

    def validate(valid)

      @valid = @valid.nil? ? valid : @valid && valid
    end

    def raise_or

      # dealing with :and and :or...

      if @valid == false

        if o = @rule['or']
          Ruote.set(@hash, @field, Rufus::Json.dup(o))
        elsif @rule['and'].nil?
          return [ @rule, @field, @value ] # validation break
        end

      elsif @valid == true and a = @rule['and']

        Ruote.set(@hash, @field, Rufus::Json.dup(a))

      elsif @valid.nil? and @value.nil? and o = (@rule['or'] || @rule['default'])

        Ruote.set(@hash, @field, Rufus::Json.dup(o))
      end

      nil
    end
  end
end

