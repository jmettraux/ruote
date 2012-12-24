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


module Ruote::Exp

  #
  # Increments or decrements the value found in a process variable or
  # a workitem field.
  #
  # One points to a var or a field in these various ways :
  #
  #   sequence do
  #     inc :var => 'counter'
  #     inc :field => 'counter'
  #     inc 'v:counter'
  #     inc 'f:counter'
  #   end
  #
  # 'inc' and 'dec' work with two types of values : numbers (the default) and
  # arrays.
  #
  #
  # == numbers
  #
  # The vanilla case of inc/dec is increasing/decreasing a value by 1.
  #
  #   dec :var => 'x'
  #
  # will decrease the value in variable 'x' by 1.
  #
  # inc/dec works with two kind of numbers, integers and floats.
  #
  # If the target var or field is not set, it will be assumed to be at zero.
  #
  # The default increment is 1 (or 1.0 for floats). It can be changed by
  # passing a value to the inc/dec expression.
  #
  #   inc 'v:x', :val => 3
  #   inc 'v:y', :val => 2.4
  #
  #
  # == arrays
  #
  # inc/dec can be used to push/pop elements in arrays held in process variables
  # or workitem fields.
  #
  # This fragment of process definition
  #
  #   sequence do
  #     set 'v:x' => %w[ a b c d ]
  #     repeat do
  #       dec 'v:x', :pos => 'head'
  #       _break :unless => '${__result__}'
  #       participant '${__result__}'
  #     end
  #   end
  #
  # is equivalent to
  #
  #   iterator :on => 'a, b, c, d', :to_var => 'x' do
  #     participant '${v:x}'
  #   end
  #
  # More details : the inc expression expects a value and it will place it
  # at the end of the current array. The :pos or :position attribute can
  # be set to 'head' to let the inc expression place the value at the head
  # of the array.
  #
  #   set 'v:x' => [ 'alfred', 'bryan' ]
  #   set 'v:customer_name' => 'charles'
  #
  #   inc 'v:x', :val => '${v:customer_name}'
  #     # the variable 'x' now holds [ 'alfred', 'bryan', 'charles' ]
  #   inc 'v:y', :val => '${v:customer_name}', :pos => 'head'
  #     # the variable 'x' now holds [ 'charles', 'alfred', 'bryan', 'charles' ]
  #
  # The 'dec' / 'decrement' variant of the expression will remove the tail
  # value (by default) of the array, or the head value if :pos is set to 'head'.
  #
  # It's also possible to remove a specific value by passing it to 'dec' :
  #
  #   set 'v:x' => [ 'alfred', 'bryan', 'carl' ]
  #   dec 'v:x', :val => 'bryan'
  #     # the variable 'x' now holds [ 'alfred', 'carl' ]
  #
  # 'dec' places the removed value in workitem field '__result__'. This trick
  # was used in the above iterator example.
  #
  # A specific variable or field can be specified via the :to_var / :to_field
  # attributes :
  #
  #   dec 'v:x', :to_v => 'a'
  #   participant :ref => '${v:a}'
  #
  #
  # == nested value
  #
  # (Since ruote 2.3.0)
  #
  # If nested expressions are provided the __result__ workitem field is
  # used for inc.
  #
  #   inc 'v:x' do
  #     set '__result__' => 3
  #   end
  #
  # will increase the value of the variable x by 3.
  #
  #
  # == push and pop
  #
  # push and pop are aliases for inc and dec respectively. There is a major
  # difference though: they'll force the target value into an array.
  #
  #   sequence do
  #     set 'v:x' => 2
  #     push 'v:x' => 3
  #   end
  #
  # will result in a variable x holding [ 2, 3 ] as value.
  #
  # Likewise,
  #
  #   pop 'v:x'
  #
  # will force a value of [] into the variable x if it wasn't previously set
  # or its value was not an array with more than one element.
  #
  class IncExpression < SequenceExpression

    names :inc, :dec, :increment, :decrement, :push, :pop

    def apply

      h.variables ||= {} # ensures a local scope

      reply(h.applied_workitem)
    end

    def reply_to_parent(workitem)

      h.applied_workitem['fields'] = workitem['fields']

      key, value = if var_key = has_attribute(:v, :var, :variable)

        var = attribute(var_key)

        [ "v:#{var}", new_value(:var, var, nil) ]

      elsif field_key = has_attribute(:f, :fld, :field)

        field = attribute(field_key)

        [ field, new_value(:field, field, nil) ]

      elsif k = att_text

        [ k, new_value(nil, k, nil) ]

      elsif kv = find_kv

        k, v = kv

        [ k, new_value(nil, k, v) ]

      else

        raise(ArgumentError.new('no variable or field to increment/decrement'))
      end

      h.variables = nil
        # the local scope is over,
        # variables set here will be set in the parent scope

      if dec? && value.is_a?(Array)
        k, car, value = value
        set_vf(k || '__result__', car)
      end

      set_vf(key, value)

      super(h.applied_workitem)
    end

    protected

    def find_kv

      compile_atts.reject { |k, v|
        COMMON_ATT_KEYS.include?(k) ||
        k.match(/^to_/)
      }.first
    end

    def dec?

      @dec ||= !!(name.match(/^dec/) or name == 'pop')
    end

    def new_value(type, key, increment)

      if type == nil && m = PREFIX_REGEX.match(key)
        type = (m[1][0, 1] == 'f' ? :field : :var)
        key = m[2]
      end

      delta = increment.nil? ? lookup_val : increment

      if delta.nil? && @msg && @msg['action'] == 'reply'
        delta = h.applied_workitem['fields']['__result__']
      end

      ndelta = Ruote.narrow_to_number(delta || 1)
      ndelta = -ndelta if dec? && ndelta

      value = type == :var ?
        lookup_variable(key) :
        Ruote.lookup(h.applied_workitem['fields'], key)

      value = case value
        when NilClass then []
        when Array then value
        else [ value ]
      end if (name == 'push' || name == 'pop')

      pos = attribute(:position) || attribute(:pos)

      return ((value || 0) + ndelta) if ndelta && (not value.is_a?(Array))

      pos ||= 'tail'
      value ||= []

      return (pos == 'tail' ? value + [ delta ] : [ delta ] + value) unless dec?

      car, cdr = if delta != nil
        (value.delete(delta) != nil ) ? [ delta, value ] : [ nil, value ]
      elsif pos == 'tail'
        [ value[-1], value[0..-2] ]
      else
        [ value[0], value[1..-1] ]
      end

      to_v, to_f = determine_tos
      key = to_v ? "v:#{to_v}" : to_f

      [ key, car, cdr ]
    end
  end
end

