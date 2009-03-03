#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/workitem'
require 'openwfe/flowexpressionid'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # A Mixin shared by CompareExpression and DefinedExpression.
  #
  module LookupMixin

    protected

      def lookup_var_value (workitem, suffix=nil)

        v = lookup_var workitem, suffix

        return lookup_variable(v) if v

        nil
      end

      def lookup_field_value (workitem, suffix=nil)

        f = lookup_field workitem, suffix

        return workitem.attributes[f] if f

        nil
      end

      def lookup_var (workitem, suffix=nil)

        do_lookup workitem, suffix, [ :variable, :var, :v ]
      end

      def lookup_field (workitem, suffix=nil)

        do_lookup workitem, suffix, [ :field, :f ]
      end

      def do_lookup (workitem, suffix, atts)

        atts.each do |a|
          a = a.to_s + '-' + suffix if suffix
          v = lookup_string_attribute a, workitem
          return v if v
        end

        nil
      end
  end

  #
  # A parent class for the 'equals' expression.
  #
  # (there should be a 'greater-than' and a 'lesser-than' expression,
  # but there are not that needed for now).
  #
  class ComparisonExpression < FlowExpression
    include LookupMixin

    def apply (workitem)

      #
      # preparing for children handling... later...
      #

      reply workitem
    end

    def reply (workitem)

      value_a, value_b = lookup_values workitem

      result = compare value_a, value_b

      ldebug { "apply() result is '#{result}'  #{@fei.to_debug_s}" }

      workitem.set_result result

      reply_to_parent workitem
    end

    protected

      #
      # The bulk job of looking up the values to compare
      #
      def lookup_values (workitem)

        value_a = lookup_value workitem
        value_b = lookup_value workitem, :prefix => 'other'

        value_c = lookup_variable_or_field_value workitem

        if not value_a and value_b
          value_a = value_c
        elsif value_a and not value_b
          value_b = value_c
        end

        [ value_a, value_b ]
      end

      #
      # Returns the value pointed at by the variable attribute or by
      # the field attribute, in that order.
      #
      def lookup_variable_or_field_value (workitem)

        lookup_var_value(workitem) || lookup_field_value(workitem)
      end
  end

  #
  # The 'equals' expression compares two values. If those values are equal,
  # the field (attribute) of the workitem named '__result__' will be
  # set to true (else false).
  #
  # Usually, this expression is used within the 'if' expression.
  #
  #   <if>
  #     <equals field-value="customer_name" other-value="Dupont" />
  #     <!-- then -->
  #     <participant ref="special_salesman" />
  #     <!-- else -->
  #     <participant ref="ordinary_salesman" />
  #   </if>
  #
  # (The 'if' expression reads the '__result__' field to route the flow
  # either towards the then branch, either towards the else one).
  #
  #
  # With a Ruby process definition, a variation on the same 'equals' :
  #
  #   equals :field_value => "phone", :other_value => "090078367"
  #   equals :field_val => "phone", :other_value => "090078367"
  #   equals :f_value => "phone", :other_value => "090078367"
  #   equals :f_val => "phone", :other_value => "090078367"
  #   equals :f_val => "phone", :other_val => "090078367"
  #
  # Thus, note that 'variable' in an expression attribute can be
  # shortened to 'var' or 'v'. 'value' can be shortened to 'val' and
  # 'field' to 'f'.
  #
  # Usually, the "test" attribute of the "if" expression is preferred
  # over this 'equals' expression, like in :
  #
  #   <if test="${f:customer_name} == Dupont">
  #     <!-- then -->
  #     <participant ref="special_salesman" />
  #     <!-- else -->
  #     <participant ref="ordinary_salesman" />
  #   </if>
  #
  # Another shortcut : the 'participant' and the 'subprocess' expressions
  # accept an optional 'if' (or 'unless') attribute, so that ifs can be
  # contracted to :
  #
  #   participant :ref => "toto", :if => "${f:customer_name} == Alfred"
  #   subprocess :ref => "special_delivery", :if => "'${f:special}' != ''"
  #
  # This also works with the implicit form of the participant and the
  # subprocess :
  #
  #   toto :if => "${f:customer_name} == Alfred"
  #   special_delivery :if => "'${f:special}' != ''"
  #
  class EqualsExpression < ComparisonExpression

    names :equals

    protected

      def compare (a, b)

        (a == b)
      end
  end

  #
  # This expression class actually implements 'defined' and 'undefined'.
  #
  # They are some kind of 'equals' for validating the presence or not
  # of a variable or a workitem field (attribute).
  #
  #   <if>
  #     <defined field="customer">
  #     <!-- then -->
  #     <subprocess ref="call_customer" />
  #   </if>
  #
  # Since OpenWFEru 0.9.17, 'defined' and 'undefined' can be easily replaced
  # by the "is [not ]set" suffix in the dollar notation :
  #
  #   <if test="${f:customer_name} is set">
  #     <!-- then -->
  #     <subprocess ref="call_customer" />
  #   </if>
  #
  class DefinedExpression < FlowExpression
    include LookupMixin

    names :defined, :undefined

    def apply (workitem)

      fname = lookup_field(workitem, 'value') || lookup_field(workitem)

      fmatch = lookup_string_attribute(:field_match, workitem)

      vname = lookup_var(workitem, 'value') || lookup_var(workitem)

      result = if fname
        workitem.has_attribute?(fname)
      elsif vname
        lookup_variable(vname) != nil
      elsif fmatch
        field_match?(workitem, fmatch)
      else
        false # when in doubt, say 'no' (even when 'undefined' ?)
      end

      result = ( ! result) \
        if result != nil and fei.expression_name == 'undefined'

      workitem.set_result result

      reply_to_parent workitem
    end

    protected

      def field_match? (workitem, regex)

        workitem.attributes.each do |k, v|

          return true if k.match(regex)
        end

        false
      end
  end

end

