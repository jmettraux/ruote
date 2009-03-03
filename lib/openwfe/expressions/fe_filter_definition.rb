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


require 'openwfe/filterdef'


module OpenWFE

  #
  # This expression binds a filter definition into a variable.
  #
  #   class TestFilter48a0 < ProcessDefinition
  #     sequence do
  #
  #       set :field => "readable", :value => "bible"
  #       set :field => "writable", :value => "sand"
  #       set :field => "randw", :value => "notebook"
  #       set :field => "hidden", :value => "playboy"
  #
  #       alice
  #
  #       filter :name => "filter0" do
  #         sequence do
  #           bob
  #           charly
  #         end
  #       end
  #
  #       doug
  #     end
  #
  #     filter_definition :name => "filter0" do
  #       field :regex => "readable", :permissions => "r"
  #       field :regex => "writable", :permissions => "w"
  #       field :regex => "randw", :permissions => "rw"
  #       field :regex => "hidden", :permissions => ""
  #     end
  #   end
  #
  # In that example, the filter definition is done for filter 'filter0'.
  #
  # A filter definition accepts 4 attributes :
  #
  # * 'name' - simply naming the filter, the filter is then bound as a variable. This is the only mandatory attribute.
  #
  # * 'closed' - by default, set to 'false'. A closed filter will not allow modifications to unspecified fields.
  #
  # * 'add' - by default, set to 'true'. When true, this filter accepts adding new fields to the filtered workitem.
  #
  # * 'remove' - by default, set to 'true'. When true, this filter accepts removing fields to the filtered workitem.
  #
  #
  # Inside of the process definition, fields are identified via regular
  # expressions ('regex'), a 'permissions' string is then expected with four
  # possible values "rw", "w", "r" and "".
  #
  class FilterDefinitionExpression < FlowExpression

    is_definition

    names :filter_definition


    #
    # Will build the filter and bind it as a variable.
    #
    def apply (workitem)

      filter = build_filter(workitem)
      filter_name = lookup_attribute(:name, workitem)

      set_variable(filter_name, filter) if filter_name and filter

      reply_to_parent(workitem)
    end

    protected

      #
      # Builds the filter (as described in the process definition)
      # and returns it.
      #
      def build_filter (workitem)

        filter = FilterDefinition.new

        # filter attributes

        type = lookup_downcase_attribute(:type, workitem)
        closed = lookup_downcase_attribute(:closed, workitem)

        filter.closed = (type == 'closed' or closed == 'true')

        add = lookup_downcase_attribute(:add, workitem)
        remove = lookup_downcase_attribute(:remove, workitem)

        filter.add_allowed = (add == 'true')
        filter.remove_allowed = (remove == 'true')

        # field by field

        raw_expression_children.each do |rawchild|

          add_field(filter, rawchild, workitem)
        end

        filter
      end

      #
      # builds and add a field (a line) of the filter.
      #
      def add_field (filter, rawchild, workitem)

        rawexp = RawExpression.new_raw(
          nil, nil, @environment_id, @application_context, rawchild)
        rawexp.load_attributes

        regex = rawexp.lookup_attribute(:regex, workitem)
        regex = rawexp.lookup_attribute(:name, workitem) unless regex

        permissions = rawexp.lookup_downcase_attribute(:permissions, workitem)

        filter.add_field(regex, permissions)
      end
  end

end

