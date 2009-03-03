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


require 'openwfe/expressions/filter'


module OpenWFE

  #
  # This expression applies a filter to the workitem used by the process
  # segment nested within it.
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
  # In this example, the filter 'filter0' is applied upon entering bob and
  # charly's sequence.
  #
  # Please note that the filter will not be enforced between bob and charly,
  # it is enforced just before entering the sequence and just after leaving
  # it.
  #
  # Note also that the ParticipantExpression accepts a 'filter' attribute,
  # thus :
  #
  #   <filter name="filter0">
  #     <participant ref="toto" />
  #   </filter>
  #
  # can be simplified to :
  #
  #   <participant ref="toto" filter="filter0" />
  #
  class FilterExpression < FlowExpression
    include FilterMixin

    names :filter

    attr_accessor :applied_workitem, :filter


    def apply (workitem)

      return reply_to_parent(workitem) if has_no_expression_child

      @applied_workitem = workitem.dup

      filter_in(workitem, :name)

      #store_itself
        # now done in apply_child()

      apply_child(first_expression_child, workitem)
    end

    def reply (workitem)

      filter_out(workitem)

      reply_to_parent(workitem)
    end
  end

end

