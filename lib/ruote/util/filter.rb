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
  def self.filter(filter, hash, options={})

    raise ArgumentError.new(
      "not a filter : #{filter}"
    ) unless filter.is_a?(Array)

    filters = or_split(filter)

    result = nil

    filters.each do |fl|

      result = begin
        do_filter(fl, hash, options)
      rescue ValidationError => err
        err
      end

      return result if result.is_a?(Hash)
        # success
    end

    raise(result) if result.is_a?(ValidationError)

    result
  end

  # Used by Ruote.filter
  #
  def self.or_split(filter)

    return filter if filter.first.is_a?(Array)
    return [ filter ] if filter.empty? or ( ! filter.include?('or'))

    # [ {}, 'or', {}, {}, 'or', {} ]

    filter.inject([ [] ]) do |result, fl|
      if fl.is_a?(Hash)
        result.last << fl
      else
        result << []
      end
      result
    end
  end

  # Used by Ruote.filter
  #
  def self.do_filter(filter, hash, options)

    hash = Rufus::Json.dup(hash)

    hash['~'] = Rufus::Json.dup(hash)
    hash['~~'] = Rufus::Json.dup(options[:double_tilde] || hash)
      # the 'originals'

    deviations = filter.collect { |rule|
      RuleSession.new(hash, rule).run
    }.flatten(1)

    hash.delete('~')
    hash.delete('~~')
    hash.delete('~~~')
      # remove the 'originals'

    if deviations.empty?
      hash
    elsif options[:no_raise]
      deviations
    else
      raise ValidationError.new(deviations)
    end
  end

  # :nodoc:
  #
  # The class used to run a rule (a line of a filter).
  #
  class RuleSession

    SKIP = %w[ and or fields field f ]
    BOOLEANS = %w[ and or ]
    NUMBER_CLASSES = [ Fixnum, Float ]
    BOOLEAN_CLASSES = [ TrueClass, FalseClass ]
    TILDE = /^~/
    RTILDE = /^\^~/
    COMMA_SPLIT = / *, */
    PIPE_SPLIT = / *\| */

    def initialize(hash, rule)

      @hash = hash
      @rule = rule

      fl = @rule['fields'] || @rule['field'] || @rule['f']

      raise ArgumentError.new(
        "filter is missing a 'fields', 'field' or 'f' arg at #{@rule.inspect}"
      ) unless fl

      if fl.is_a?(String)
        fl = fl.gsub(/!/, '\.') if REGEX_IN_STRING.match(fl)
        fl = Ruote.regex_or_s(fl)
      end

      @fields = if fl.is_a?(Regexp)

        # when restoring, you look at the old keys, not the current ones

        keys = Ruote.flatten_keys(@rule['restore'] ? @hash['~~'] : @hash)
        keys = keys.reject { |k| TILDE.match(k) } unless RTILDE.match(fl.source)

        # now only keep the keys that match our regexp

        keys.each_with_object([]) { |k, a|
          m = fl.match(k)
          a << [ k, Ruote.lookup(@hash, k), m[1..-1] ] if m
        }

      elsif fl.is_a?(String) and PIPE_SPLIT.match(fl)

        fields = fl.split(PIPE_SPLIT).collect { |field|
          val = Ruote.lookup(@hash, field)
          val.nil? ? nil : [ field, val, nil ]
        }.compact

        fields.empty? ? [ [ fl, nil, nil ] ] : fields
          # if no fields where found, place fake fl field to force failure

      else

        (fl.is_a?(Array) ? fl : fl.to_s.split(COMMA_SPLIT)).collect { |field|
          [ field,  Ruote.lookup(@hash, field), nil ]
        }
      end
    end

    def run

      keys = @rule.keys - SKIP
      validation = (@rule.keys & BOOLEANS).empty?

      if validation and @fields.empty? and keys.empty?
        fl = @rule['fields'] || @rule['field'] || @rule['f']
        return [ [ @rule, fl, nil ] ] # validation break
      end

      @fields.collect { |field, value, matches|

        valid = nil

        if keys.empty?

          valid = (value != nil)

        else

          keys.each do |k|

            v = @rule[k]

            m = "_#{k}"
            next unless self.respond_to?(m)

            r = self.send(m, field, value, matches, k, v)

            valid = false if r == false
          end
        end

        raise_or_and(valid, field, value)

      }.compact
    end

    protected

    def _remove(field, value, matches, m, v)

      Ruote.unset(@hash, field)

      nil
    end
    alias _rm _remove
    alias _delete _remove
    alias _del _remove

    def _set(field, value, matches, m, v)

      Ruote.set(@hash, field, Rufus::Json.dup(v))

      nil
    end
    alias _s _set

    def adjust_target(target, matches)

      target.gsub(/\\\d+/) { |digit| matches[digit.to_i - 1] rescue '' }
    end

    def _copy_to(field, value, matches, m, v)

      v = adjust_target(v, matches)

      Ruote.set(@hash, v, Rufus::Json.dup(value))
      Ruote.unset(@hash, field) if m == 'move_to' or m == 'mv_to'

      nil
    end
    alias _cp_to _copy_to
    alias _move_to _copy_to
    alias _mv_to _copy_to


    def _copy_from(field, value, matches, m, v)

      Ruote.set(@hash, field, Rufus::Json.dup(Ruote.lookup(@hash, v)))
      Ruote.unset(@hash, v) if m == 'move_from' or m == 'mv_from'

      nil
    end
    alias _cp_from _copy_from
    alias _move_from _copy_from
    alias _mv_from _copy_from

    # Used by both _merge_to and _merge_from
    #
    def do_merge(field, target, value)

      value = Rufus::Json.dup(value)

      if target.is_a?(Array)
        target.push(value)
      elsif value.is_a?(Hash)
        target.merge!(value)
      else # deal with non Hash
        target[field.split('.').last] = value
      end

      target.delete('~')
      target.delete('~~')
    end

    def _merge_to(field, value, matches, m, v)

      target = Ruote.lookup(@hash, v)

      return unless target.respond_to?(:merge!) or target.is_a?(Array)

      do_merge(field, target, value)

      Ruote.unset(@hash, field) if m == 'migrate_to' or m == 'mi_to'

      nil
    end
    alias _mg_to _merge_to
    alias _push_to _merge_to
    alias _pu_to _merge_to
    alias _migrate_to _merge_to
    alias _mi_to _merge_to

    def _merge_from(field, value, matches, m, v)

      return unless value.respond_to?(:merge!) or value.is_a?(Array)

      do_merge(v, value, Ruote.lookup(@hash, v))

      Ruote.unset(@hash, v) if v != '.' and m.match(/^mi(grate)?_from$/)

      nil
    end
    alias _mg_from _merge_from
    alias _push_from _merge_from
    alias _pu_from _merge_from
    alias _migrate_from _merge_from
    alias _mi_from _merge_from

    def _restore(field, value, matches, m, v)

      prefix = v == true ? '~~' : v.to_s

      Ruote.set(@hash, field, Ruote.lookup(@hash, "#{prefix}.#{field}"))

      nil
    end
    alias _restore_from _restore
    alias _rs _restore

    def _take(field, value, matches, m, v)

      unless @hash.has_key?('~~~')

        @hash['~~~'] = @hash.keys.select { |k|
          ! k.match(/^\~+$/)
        }.each_with_object({}) { |k, h|
          h[k] = @hash.delete(k)
        }

        @hash.merge!(@hash['~~'])
        @hash.merge!(@hash['~~~']) if m == 'discard' && v != 'all'
      end

      if m == 'take'
        @hash[field] = @hash['~~~'][field]
      elsif v != 'all'
        @hash.delete(field)
      end

      nil
    end
    alias _discard _take

    def _size(field, value, matches, m, v)

      v = v.is_a?(String) ? v.split(',').collect { |i| i.to_i } : Array(v)

      if value.respond_to?(:size)
        (v.first ? value.size >= v.first : true) and
        (v.last ? value.size <= v.last : true)
      else
        false
      end
    end
    alias _sz _size

    def _empty(field, value, matches, m, v)

      # 'empty' => '30%' could be fun ;-)

      (value.respond_to?(:empty?) ? value.empty? : false) == v
    end
    alias _e _empty

    def _in(field, value, matches, m, v)

      (v.is_a?(Array) ?
        v :
        v.to_s.split(',').collect { |e| e.strip }
      ).include?(value)
    end
    alias _i _in

    def _has(field, value, matches, m, v)

      v = v.is_a?(Array) ? v : v.to_s.split(',').collect { |e| e.strip }

      if value.is_a?(Hash)
        (value.keys & v) == v
      elsif value.is_a?(Array)
        (value & v) == v
      else
        false
      end
    end
    alias _h _has

    def _includes(field, value, matches, m, v)

      case value
        when Array then value.include?(v)
        when Hash then value.values.include?(v)
        else false
      end
    end

    def _type(field, value, matches, m, v)

      of_type?(value, v)
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

      types.inject(false) do |valid, type|

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
    end

    def children_of_type?(values, types)

      return false unless values.is_a?(Array) or values.is_a?(Hash)

      values = values.is_a?(Array) ? values : values.values

      values.each { |v| of_type?(v, types) or return(false) }

      true
    end

    def _match(field, value, matches, m, v)

      value.nil? ? false : value.to_s.match(v) != nil
    end
    alias _m _match

    def _smatch(field, value, matches, m, v)

      value.is_a?(String) ? value.match(v) != nil : false
    end
    alias _sm _smatch

    def _is(field, value, matches, m, v)

      value == v
    end

    def _valid(field, value, matches, m, v)

      v.to_s == 'true'
    end
    alias _v _valid

    def raise_or_and(valid, field, value)

      # dealing with :and and :or...

      if valid == false

        if o = @rule['or']
          Ruote.set(@hash, field, Rufus::Json.dup(o))
        elsif @rule['and'].nil?
          return [ @rule, field, value ] # validation break
        end

      elsif a = @rule['and']

        Ruote.set(@hash, field, Rufus::Json.dup(a))

      elsif value.nil? and o = (@rule['or'] || @rule['default'])

        Ruote.set(@hash, field, Rufus::Json.dup(o))
      end

      nil
    end
  end

  #   Ruote.flatten_keys({ 'a' => 'b', 'c' => [ 1, 2, 3 ] })
  #     # =>
  #   [ 'a', 'c', 'c.0', 'c.1', 'c.2' ]
  #
  def self.flatten_keys(o, prefix='', accu=[])

    if o.is_a?(Array)

      o.each_with_index do |elt, i|
        pre = "#{prefix}#{i}"
        accu << pre
        flatten_keys(elt, pre + '.', accu)
      end

    elsif o.is_a?(Hash)

      o.keys.sort.each do |key|
        pre = "#{prefix}#{key}"
        accu << pre
        flatten_keys(o[key], pre + '.', accu)
      end
    end

    accu
  end
end

