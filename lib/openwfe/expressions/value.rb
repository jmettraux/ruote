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

module OpenWFE

  #
  # A small mixin providing value for looking up the attributes
  # variable/var/v and field/fld/f.
  #
  module ValueMixin

    #
    # Expressions that include the ValueMixin let it gather values and
    # then, in their reply() methods do the job with the values.
    # The gathering task is performed by the ValueMixin.
    #
    def apply (workitem)

      escape = lookup_boolean_attribute('escape', workitem, false)

      if raw_children.length < 1

        workitem.attributes[FIELD_RESULT] =
          lookup_value(workitem, :escape => escape)

        reply(workitem)
        return
      end

      child = raw_children.first

      if child.is_a?(Array) # child is an expression

        if get_expression_map.get_class(child[0]) == DefineExpression

          workitem.attributes[FIELD_RESULT] = child # bind process

          reply(workitem)
        else

          apply_child(0, workitem) # apply child
        end

      else # child is a piece of text

        workitem.attributes[FIELD_RESULT] =
          fetch_text_content(workitem, escape)

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
          return v if v
        end

        nil
      end
  end

end

