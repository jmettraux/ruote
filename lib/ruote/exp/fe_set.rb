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


module Ruote::Exp

  #
  # Setting a workitem field or a process variable.
  #
  #   sequence do
  #     set :field => 'subject', :value => 'food and beverage'
  #     set :field => 'date', :val => 'tomorrow'
  #     participant :ref => 'attendees'
  #   end
  #
  # :field can be abbreviated to :f or :fld. :variable can be abbreviated to
  # :v or :var. Likewise, :val and :value are interchangeable.
  #
  # == field_value, variable_value
  #
  # Usually, grabbing a value from a field or a value will look like
  #
  #   set :f => 'my_field', :value => '${v:my_variable}'
  #
  # But doing those ${} substitutions always result in a string result. What
  # if the variable or the field holds a non-string value ?
  #
  #   set :f => 'my_field', :var_value => 'my_variable'
  #
  # Is the way to go then. 'set' understands v_value, var_value, variable_value
  # and f_value, fld_value and field_value.
  #
  # == :escape
  #
  # If the value to insert contains ${} stuff but this has to be preserved,
  # setting the attribute :escape to true will do the trick.
  #
  #   set :f => 'my_field', :value => 'oh and ${whatever}', :escape => true
  #
  # == ruote 2.0's shorter form
  #
  # Ruote 2.0 introduces a shorter form for the 'set' expression :
  #
  #   sequence do
  #     set :field => 'f', :value => 'val0'
  #     set :variable => 'v', :value => 'val1'
  #     set :field => 'f_${v:v}', :value => 'val2'
  #   end
  #
  # can be rewritten as
  #
  #   sequence do
  #     set 'f:f' => 'val0'
  #     set 'v:v' => 'val1'
  #     set 'f:f_${v:v}' => 'val2'
  #   end
  #
  # since 'f:' is the default for the 'dollar notation', the shortest form
  # becomes
  #
  #   sequence do
  #     set 'f' => 'val0'
  #     set 'v:v' => 'val1'
  #     set 'f_${v:v}' => 'val2'
  #   end
  #
  class SetExpression < FlowExpression

    names :set, :unset

    def apply

      opts = { :escape => attribute(:escape) }

      value = lookup_val(opts)
        # a nil value is totally OK

      if var_key = has_attribute(:v, :var, :variable)

        set_v(attribute(var_key), value)

      elsif field_key = has_attribute(:f, :fld, :field)

        set_f(attribute(field_key), value)

      elsif value == nil && kv = expand_atts(opts).find { |k, v| k != 'escape' }

        set_vf(*kv)

      else

        raise ArgumentError.new(
          "missing a variable or field target in #{tree.inspect}")
      end

      reply_to_parent(h.applied_workitem)
    end

    def reply (workitem)

      # never called
    end

    protected

    def set_v (key, value)

      if name == 'unset'
        unset_variable(key)
      else
        set_variable(key, value)
      end
    end

    def set_f (key, value)

      if name == 'unset'
        h.applied_workitem['fields'].delete(key)
      else
        Ruote.set(h.applied_workitem['fields'], key, value)
      end
    end

    PREFIX_REGEX = /^([^:]+):(.+)$/ unless defined?(PREFIX_REGEX)

    def set_vf (key, value)

      field = true

      if m = PREFIX_REGEX.match(key)
        field = m[1][0, 1] == 'f'
        key = m[2]
      end

      field ? set_f(key, value) : set_v(key, value)
    end
  end
end

