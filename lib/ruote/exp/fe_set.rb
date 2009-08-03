#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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

require 'ruote/exp/flowexpression'


module Ruote

  class SetExpression < FlowExpression

    names :set, :unset

    def apply

      reply(@applied_workitem)
    end

    def reply (workitem)

      value = if name == 'unset'
        nil
      elsif val_key = has_attribute(:val, :value)
        attribute(val_key, workitem)
      else
        child_text(workitem) # TODO : test that !!!
      end

      if var_key = has_attribute(:v, :var, :variable)

        var = attribute(var_key, workitem)

        if name == 'unset'
          unset_variable(var)
        else
          set_variable(var, value)
        end

      elsif field_key = has_attribute(:f, :fld, :field)

        field = attribute(field_key, workitem)

        if name == 'unset'
          workitem.attributes.delete(field)
        else
          Ruote.set(workitem.fields, field, value)
        end

      else

        raise ArgumentError.new(
          "missing a variable or field target in #{tree.inspect}")
      end

      reply_to_parent(workitem)
    end
  end
end

