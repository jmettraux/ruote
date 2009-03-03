#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
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


module OpenWFE

  #
  # This expression takes its root in this "trouble ticket blog post" :
  #
  #   http://jmettraux.wordpress.com/2008/01/04/the-trouble-ticket-process/
  #
  # In this post, the "step" was implemented directly in the OpenWFEru
  # process definition language.
  #
  # It's been turned into an expression and it's not limited anymore to
  # the concept "state is a participant, transition points to a subprocess",
  # state can now point to a subprocess as well as to a participant, idem
  # for a transition.
  #
  # In other words, this "step" expression allows you to write
  # state-transition process definitions in OpenWFEru (the Ruote workflow
  # engine). But don't abuse it. Classical OpenWFEru constructs can
  # do most of the job.
  #
  # An interesting aspect of the "step" expression is that it can remove
  # the need for some "if" expression constructs (well the fact
  #
  #   class ProcDef0 < OpenWFE::ProcessDefinition
  #
  #     sequence do
  #
  #     step "Alfred", :outcomes => [ 'blue_pen', 'red_pen' ]
  #       # Alfred gets to choose between a blue pen and a red pen
  #
  #     participant "Bob"
  #       # flow resumes with Bob in a classical way (sequence)
  #     end
  #
  #     define "blue_pen" do
  #     # ... Alfred buying a blue pen
  #     end
  #     define "red_pen" do
  #     # ... Alfred buying a red pen
  #     end
  #   end
  #
  # in XML it would look like :
  #
  #   <sequence>
  #    <step ref="Alfred" outcomes="blue_pen, red_pen" />
  #    <participant ref="Bob" />
  #   </sequence>
  #
  # You can specify a default outcome (else if the outcome doesn't correspond
  # to a participant or a subprocess, the flow will cease) :
  #
  #   <step ref="toto" outcomes="left, right" default="right" />
  #
  # For some more discussions about Ruote and state-transition see
  #
  #   http://groups.google.com/group/openwferu-dev/t/16e713c1313cb2fa
  #
  class StepExpression < FlowExpression

    names :step

    attr_accessor :outcomes
    attr_accessor :default


    def apply (workitem)

      step =
        lookup_attribute(:ref, workitem) ||
        fetch_text_content(workitem)

      # keeping track of outcomes and default as found at apply time

      @outcomes = lookup_array_attribute(
        :outcomes, workitem, :to_s => true)

      @default = lookup_attribute(
        :default, workitem, :to_s => true)

      #store_itself
        # now done in tlaunch_child()

      # launching the 'step' itself

      template = [
        step.to_s, # expression name
        lookup_attributes(workitem), # attributes
        [], # children
      ]

      get_expression_pool.tlaunch_child(
        self, template, 0, workitem, :register_child => true)
    end

    def reply (workitem)

      outcome = workitem.fields.delete('outcome')
      outcome = outcome.to_s if outcome

      outcome = @default \
        if @outcomes and (not @outcomes.include?(outcome))

      return reply_to_parent(workitem) \
        unless outcome

      template = [
        outcome.to_s, # expression name
        {}, # attributes
        [], # children
      ]

      get_expression_pool.substitute_and_apply(self, template, workitem)
    end
  end

end

