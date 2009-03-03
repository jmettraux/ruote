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


require 'openwfe/expressions/flowexpression'
require 'openwfe/expressions/fe_sequence'


module OpenWFE

  #
  # The <process-definition> expression.
  #
  #   <process-definition name="myprocess" revision="2">
  #     <sequence>
  #       <participant ref="alpha" />
  #       <subprocess ref="sub0" />
  #     </sequence>
  #     <process-definition name="sub0">
  #       <participant ref="bravo" />
  #     </process-definition>
  #   </process-definition>
  #
  # In a Ruby process definition :
  #
  #   class Test0 < OpenWFE::ProcessDefinition
  #
  #     sequence do
  #       sub0
  #       sub1
  #       sub2
  #       sub3
  #     end
  #
  #     process_definition :name => "sub0" do
  #       _print "sub0"
  #     end
  #     define :name => "sub1" do
  #       _print "sub1"
  #     end
  #     process_definition "sub2" do
  #       _print "sub2"
  #     end
  #     define "sub3" do
  #       _print "sub3"
  #     end
  #   end
  #
  # It is most often used with its "process-definition" name, but "define"
  # and "workflow-definition" are accepted as well.
  #
  class DefineExpression < SequenceExpression

    is_definition

    names :define, :process_definition, :workflow_definition

    #
    # A pointer to the body expression of this process definition.
    #
    attr_accessor :body_index

    #
    # keeping track of whether the body of the process got started or not
    #
    attr_accessor :applied_body

    #
    # Called at the end of the 'evaluation', the 'apply' operation on
    # the body of the definition is done here.
    #
    def reply_to_parent (workitem)

      return super(workitem) if @body_index == nil or @applied_body
        # no body or body just got applied

      # apply body of process definition now

      @applied_body = true

      #store_itself
        # now done in apply_child()

      apply_child(@body_index, workitem)
    end

    protected

      def next_child_index (returning_fei)

        child_index = super

        return nil unless child_index

        child = raw_children[child_index]

        if child.is_a?(Array) && ( ! [ 'param', 'parameter' ].include?(child[0]))

          if get_expression_map.get_class(child[0]) == DefineExpression

            name = child[1]['name'] || child[2].first

            raise "process definition without a 'name' attribute" \
              unless name

            set_variable(name.to_s, child)

          elsif get_expression_map.is_definition?(child[0])

            return child_index # let it get 'applied'

          elsif @body_index == nil

            @body_index = child_index
            store_itself
          end

        end

        next_child_index(child_index)
      end
  end

end

