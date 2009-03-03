#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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
  # This mixin adds filtering capabilities to a FlowExpression.
  #
  # It's used by the 'participant' and 'filter' expressions.
  #
  module FilterMixin

    attr_accessor :filter

    #
    # Used when the workitem enters the 'filtered zone'. Will replace
    # the attributes of the workitem with filtered ones.
    # Assumes the original workitem is kept under @applied_workitem.
    #
    def filter_in (workitem, filter_attribute_name=:filter)

      @filter = get_filter(filter_attribute_name, workitem)

      return unless @filter

      workitem.attributes = @filter.filter_in(workitem.attributes)
      workitem.filter = @filter.dup
    end

    #
    # Prepares the workitem for leaving the 'filtered zone'. Makes sure
    # hidden and unwritable fields haven't been tampered with. Enforces
    # the 'add_ok', 'remove_ok', 'closed' filter directives.
    # Assumes the original workitem is kept under @applied_workitem.
    #
    def filter_out (incoming_workitem)

      return unless @filter

      incoming_workitem.filter = nil

      incoming_workitem.attributes = @filter.filter_out(
        @applied_workitem.attributes, incoming_workitem.attributes)
    end

    protected

      #
      # Fetches the filter pointed at via the 'filter' attribute
      # of the including expression class.
      #
      def get_filter (filter_attribute_name, workitem)

        filter_name = lookup_attribute(filter_attribute_name, workitem)

        return nil unless filter_name

        lookup_variable(filter_name)
      end
  end

end

