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
require 'openwfe/expressions/value'


module OpenWFE

  #
  # The 'set' expression is used to set the value of a (process) variable or
  # a (workitem) field.
  #
  #   <set field="price" value="CHF 12.00" />
  #   <set variable="/stage" value="3" />
  #   <set variable="/stage" field-value="f_stage" />
  #   <set field="stamp" value="${r:Time.now.to_i}" />
  #
  # (Notice the usage of the dollar notation in the last exemple).
  #
  # 'set' expressions may be placed outside of a process-definition body,
  # they will be evaluated sequentially before the body gets applied
  # (executed).
  #
  # Shorter attributes are OK :
  #
  #   <set f="price" val="CHF 12.00" />
  #   <set v="/stage" val="3" />
  #   <set v="/stage" field-val="f_stage" />
  #   <set f="stamp" val="${r:Time.now.to_i}" />
  #
  #   set :f => "price", :val => "USD 12.50"
  #   set :v => "toto", :val => "elvis"
  #
  # In case you need the value not to be evaluated if it contains
  # dollar expressions, you can do
  #
  #   set :v => "v0", :val => "my ${template} thing", :escape => true
  #
  # to prevent evaluation (i.e. to escape).
  #
  class SetValueExpression < FlowExpression
    include ValueMixin

    is_definition

    names :set

    def reply (workitem)

      vkey = lookup_variable_attribute(workitem)
      fkey = lookup_field_attribute(workitem)

      value = workitem.get_result

      if vkey
        set_variable(vkey, value)
      elsif fkey
        workitem.set_attribute(fkey, value)
      else
        raise "'variable' or 'field' attribute missing from 'set' expression"
      end

      reply_to_parent(workitem)
    end
  end

  #
  # 'unset' removes a field or a variable.
  #
  #   unset :field => "price"
  #   unset :variable => "eval_result"
  #
  class UnsetValueExpression < FlowExpression
    include ValueMixin

    names :unset

    def apply (workitem)

      vkey = lookup_variable_attribute(workitem)
      fkey = lookup_field_attribute(workitem)

      if vkey
        delete_variable(vkey)
      elsif fkey
        workitem.unset_attribute(fkey)
      else
        raise "attribute 'variable' or 'field' is missing for 'unset' expression"
      end

      reply_to_parent(workitem)
    end
  end

end

