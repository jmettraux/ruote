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
    ##attr_accessor :body_fei
    attr_accessor :body_index

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

        if child.is_a?(Array)

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

