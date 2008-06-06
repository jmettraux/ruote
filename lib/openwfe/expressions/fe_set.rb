#
#--
# Copyright (c) 2006-2008, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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

      value = workitem.attributes[FIELD_RESULT]

      #puts "value is '#{value}'"

      if vkey
        set_variable vkey, value
      elsif fkey
        workitem.set_attribute fkey, value
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
        workitem.unset_attribute fkey
      else
        raise "attribute 'variable' or 'field' is missing for 'unset' expression"
      end

      reply_to_parent workitem
    end
  end

end

