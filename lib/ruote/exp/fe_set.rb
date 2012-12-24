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

require 'ruote/exp/fe_sequence'


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
  # == :override / :over
  #
  # (attribute introduced in ruote 2.3.0)
  #
  # When setting a variable with no slash prefix, the target will always be the
  # most local scope. When one wants to purposely override/overwrite an already
  # set variable, the attribute :override can be set to true.
  #
  # In this example, although the second 'set' happens in its own scope, the
  # variable v0, will be set to 'b' in the initial (top) scope:
  #
  #   pdef = Ruote.define do
  #     set 'v:v0' => 'a'
  #     sequence :scope => true do
  #       set 'v:v0' => 'b', :over => true
  #     end
  #   end
  #
  # :over(ride) tells the 'set' expression to locate where the var is set
  # and change the value there.
  #
  # :over is ignored for process (/) and engine (//) variables. It has no
  # meaning for workitem fields.
  #
  # When :over is set to 'sub' (or :sub), the :over => true behaviour is
  # followed, but it doesn't cross into the parent subprocess.
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
  # === shorter form and non-string values
  #
  # Dollar substitutions like '${a}' will always squash the field or the
  # variable into a string. It's useful, especially when one is doing
  # 'user-${name}', but when the field (or variable) is an array or an hash
  #
  #   set 'f' => '${array}'
  #
  # will put the string representation of array into the field 'f', not
  # a copy of the array itself.
  #
  # This will copy the array into the field 'f':
  #
  #   set 'f' => '$f:array'
  #
  # Note the mandatory 'f:'. There is a thing to be aware of: if the field
  # array is missing, it will resolve into "$f:array" (no substitution at all).
  #
  # There is always the old-style fallback:
  #
  #   set :field => 'f', :field_value => 'array'
  #
  #
  # == set and rset
  #
  # Some gems (Sinatra) for example may provide a set method that hides calls
  # to set when building process definitions (see http://groups.google.com/group/openwferu-users/browse_thread/thread/9ac606e30ada686e)
  #
  # A workaround is to write 'rset' instead of 'set'.
  #
  #   rset 'customer' => 'Jeff'
  #
  #
  # == unset
  #
  # 'unset' is the counterpart to 'set', it removes a field (or a variable)
  #
  #   unset :field => 'customer_name'
  #   unset :f => 'customer_name'
  #   unset :variable => 'vx'
  #   unset :var => 'vx'
  #   unset :v => 'vx'
  #
  # or simply
  #
  #   unset 'f:customer_name'
  #   unset 'customer_name' # yes, it's field by default
  #   unset 'v:vx'
  #
  #
  # == using set with a block
  #
  # (not a very common usage, introduced by ruote 2.3.0)
  #
  # 'set' can be used with a block. It then behaves like a 'sequence' and
  # picks its value in the workitem field named '__result__'.
  #
  #   set 'customer_name' do
  #     participant 'alice'
  #     participant 'bob'
  #   end
  #
  # Here, alice or bob may set the field '__result__' to some value,
  # that will get picked as the value of the field 'customer_name'.
  #
  # Note that inside the set, a blank variable scope will be used (like in
  # a 'let).
  #
  #
  # == __result__
  #
  # 'set' and 'unset' place the [un]set value in the field named __result__.
  #
  #   sequence do
  #     set 'f0' => 2
  #     participant 'x${__result__}''
  #   end
  #
  # will route a workitem to the participant named 'x2'.
  #
  class SetExpression < SequenceExpression

    names :rset, :set, :unset

    def apply

      h.variables ||= {} # ensures a local scope

      reply(h.applied_workitem)
    end

    def reply_to_parent(workitem)

      h.applied_workitem['fields'] = workitem['fields']
        # since set_vf and co work on h.applied_workitem...

      opts = { :escape => attribute(:escape) }
      compiled_atts = compile_atts(opts)

      kv = find_kv(compiled_atts)

      over = attribute(:override) || attribute(:over)
      unset = name == 'unset'

      h.variables = nil
        # the local scope is over,
        # variables set here will be set in the parent scope

      value = if tree_children.empty?
        lookup_val(opts)
      else
        h.applied_workitem['fields']['__result__']
      end
        #
        # a nil value is totally OK

      result = if var_key = has_attribute(:v, :var, :variable)

        set_v(attribute(var_key), value, :unset => unset, :override => over)

      elsif field_key = has_attribute(:f, :fld, :field)

        set_f(attribute(field_key), value, :unset => unset)

      elsif value == nil && kv

        kv << { :unset => unset, :override => over }

        set_vf(*kv)

      elsif kv

        set_vf(kv.first, value, :unset => unset, :override => over)

      else

        raise ArgumentError.new(
          "missing a variable or field target in #{tree.inspect}")
      end

      h.applied_workitem['fields']['__result__'] = result

      super(h.applied_workitem)
    end

    protected

    def find_kv(atts)

      forbidden = COMMON_ATT_KEYS + %w[ escape over override ]

      atts.find { |k, v| ! forbidden.include?(k) }
    end
  end
end

