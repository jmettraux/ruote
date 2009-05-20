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


module OpenWFE

  #
  # A small mixin providing value for looking up the attributes
  # variable/var/v and field/fld/f.
  #
  module ValueMixin

    # Expressions that include the ValueMixin let it gather values and
    # then, in their reply() methods do the job with the values.
    # The gathering task is performed by the ValueMixin.
    #
    def apply (workitem)

      escape = lookup_boolean_attribute('escape', workitem, false)

      if raw_children.length < 1

        workitem.set_result(lookup_value(workitem, :escape => escape))

        reply(workitem)
        return
      end

      child = raw_children.first

      if child.is_a?(Array) # child is an expression

        if get_expression_map.get_class(child[0]) == DefineExpression

          workitem.set_result(child) # bind process

          reply(workitem)
        else

          apply_child(0, workitem) # apply child
        end

      else # child is a piece of text

        workitem.set_result(fetch_text_content(workitem, escape))

        reply(workitem)
      end
    end

    def lookup_variable_attribute (workitem)

      lookup [ 'variable', 'var', 'v' ], workitem
    end

    def lookup_field_attribute (workitem)

      lookup [ 'field', 'fld', 'f' ], workitem
    end

    private

    def lookup (name_array, workitem)

      name_array.each do |n|

        v = lookup_string_attribute(n, workitem)

        return v if v != nil
          # covers v == false as well
      end

      nil
    end
  end

end

