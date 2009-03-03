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

require 'openwfe/workitem'
require 'openwfe/expressions/merge'


module OpenWFE

  #
  # Saves a copy of the current workitem to a variable or saves the
  # attributes of the current workitem into a field (of that current
  # workitem).
  #
  #  save :to_variable => "/wix"
  #    #
  #    # saves a copy of the current workitem to the process
  #    # level variable "wix"
  #
  #  save :to_field => "old_version"
  #    #
  #    # saves a copy of the current workitem attributes in the
  #    # field 'old_version' of that current workitem.
  #
  # 'save' is often used in conjuntion with 'restore'
  # (RestoreWorkItemExpression).
  #
  class SaveWorkItemExpression < FlowExpression

    names :save

    def apply (workitem)

      field = lookup_string_attribute(:to_field, workitem)
      variable = lookup_string_attribute(:to_variable, workitem)

      wi = workitem.dup

      if field

        workitem.set_attribute(field, wi.attributes)

      elsif variable

        set_variable(variable, wi)
      end

      # else, simply don't save

      reply_to_parent(workitem)
    end
  end

  #
  # "restore" is often used in conjunction with "save"
  # (SaveWorkItemExpression).
  #
  # It can restore a workitem saved to a variable (it will actually
  # restore the payload of that workitem) or transfer the content of a field
  # as top attribute field.
  #
  #   restore :from_variable => "freezed_workitem"
  #     #
  #     # takes the freezed payload at 'freezed_workitem' and makes it
  #     # the payload of the current workitem
  #
  #   restore :from_field => "some_data"
  #     #
  #     # replaces the payload of the current workitem with the hash
  #     # found in the field "some_data"
  #
  #   restore :from_variable => "v", :to_field => "f"
  #     #
  #     # will copy the payload saved under variable "v" as the value
  #     # of the field "f"
  #
  #   restore :from_variable => "v", :merge_lead => :current
  #     #
  #     # will restore the payload of the workitem saved under v
  #     # but if fields of v are already present in the current workitem
  #     # the current values will be kept
  #
  #   restore :from_variable => "v", :merge_lead => :restored
  #     #
  #     # will restore the payload of the workitem saved under v
  #     # but the workitem v payload will have priority.
  #
  # Beware : you should not restore from a field that is not a hash. The
  # top level attributes (payload) of a workitem should always be a hash.
  #
  # Since OpenWFEru 0.9.17, the 'set-fields' alias can be used for restore.
  #
  #   sequence do
  #     set_fields :value => {
  #       "customer" => { "name" => "Zigue", "age" => 34 },
  #       "approved" => false }
  #     _print "${f:customer.name} (${f:customer.age}) ${f:approved}"
  #   end
  #
  # Along with this new alias, the expression now behave much like the 'set'
  # expression, but still, targets the whole workitem payload.
  #
  # Note that "set-fields" can be used outside of the body of a process
  # definition (along with "set") to separate 'data preparation' from
  # actual process definition.
  #
  #   class Test44b6 < ProcessDefinition
  #     set_fields :value => {
  #       "customer" => { "name" => "Zigue", "age" => 34 },
  #       "approved" => false }
  #     sequence do
  #       _print "${f:customer.name} (${f:customer.age}) ${f:approved}"
  #     end
  #   end
  #
  # Using set_fields at the beginning of a process can be useful for setting
  # up forms (keys without values for now).
  #
  #   set_fields :value => {
  #     "name" => "",
  #     "address" => "",
  #     "email" => ""
  #   }
  #
  class RestoreWorkItemExpression < FlowExpression
    include MergeMixin
    include ValueMixin

    names :restore, :set_fields

    is_definition
      # so that in can be placed outside of process definition bodies


    def reply (workitem)

      from_field = lookup_string_attribute :from_field, workitem
      from_variable = lookup_string_attribute :from_variable, workitem

      merge_lead = lookup_sym_attribute :merge_lead, workitem

      merge_lead = nil \
        unless [ nil, :current, :restored ].include?(merge_lead)

      value = workitem.attributes[FIELD_RESULT]

      source = if from_field

        att = workitem.lookup_attribute(from_field)

        lwarn {
          "apply() field '#{from_field}' is NOT a hash, " +
          "restored anyway"
        } unless att.kind_of?(Hash)

        att

      elsif from_variable

        lookup_variable(from_variable)

      elsif value

        value

      else

        nil
      end

      if source

        workitem = if merge_lead
          do_merge(merge_lead, workitem, source)
        else
          do_overwrite(workitem, source)
        end
      end
      # else, don't restore anything

      reply_to_parent(workitem)
    end

    protected

    #
    # The default case, restored values simply overwrite current
    # values.
    #
    def do_overwrite (workitem, source)

      return workitem unless source

      attributes = if source.kind_of?(WorkItem)
        OpenWFE.fulldup(source.attributes)
      else
        source
      end

      to_field = lookup_string_attribute(:to_field, workitem)

      if to_field
        workitem.set_attribute(to_field, attributes)
      else
        workitem.attributes = attributes
      end

      workitem
    end

    #
    # If the attribute 'merge-lead' (or 'merge_lead') is specified,
    # the workitems get merged.
    #
    def do_merge (merge_lead, workitem, source)

      if source.kind_of?(Hash)
        wi = InFlowWorkItem.new
        wi.attributes = source
        source = wi
      end

      wi_target, wi_source = if merge_lead == :current
        [ source, workitem ]
      else
        [ workitem, source ]
      end

      merge_workitems(wi_target, wi_source)
    end
  end

end

