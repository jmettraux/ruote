#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

      @filter = get_filter filter_attribute_name, workitem

      return unless @filter

      workitem.attributes = @filter.filter_in workitem.attributes
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

        filter_name = lookup_attribute filter_attribute_name, workitem

        return nil unless filter_name

        lookup_variable filter_name
      end
  end

end

