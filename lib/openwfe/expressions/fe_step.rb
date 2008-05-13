#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
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


module OpenWFE

    #
    # This expression takes its root in this "trouble ticket blog post" :
    #
    #     http://jmettraux.wordpress.com/2008/01/04/the-trouble-ticket-process/
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
    #     class ProcDef0 < OpenWFE::ProcessDefinition
    #
    #       sequence do
    #
    #         step "Alfred", :outcomes => [ 'blue_pen', 'red_pen' ]
    #           # Alfred gets to choose between a blue pen and a red pen
    #
    #         participant "Bob"
    #           # flow resumes with Bob in a classical way (sequence)
    #       end
    #
    #       define "blue_pen" do
    #         # ... Alfred buying a blue pen
    #       end
    #       define "red_pen" do
    #         # ... Alfred buying a red pen
    #       end
    #     end
    #
    # For some more discussions about Ruote and state-transition see
    #
    #     http://groups.google.com/group/openwferu-dev/t/16e713c1313cb2fa 
    #
    class StepExpression < FlowExpression

        names :step


        #attr_accessor :out
        attr_accessor :outcomes
        attr_accessor :default


        def apply (workitem)

            step = lookup_attribute(:step, workitem) || @children.first

            #@out = false

            # keeping track of outcomes and default as found at apply time

            @outcomes = lookup_array_attribute(
                :outcomes, workitem, :to_s => true)

            @default = lookup_attribute(
                :default, workitem, :to_s => true)

            store_itself

            # launching the 'step' itself

            template = [ 
                step.to_s, # expression name
                lookup_attributes(workitem), # attributes
                [], # children
            ]

            get_expression_pool.tlaunch_child(
                self, template, 0, workitem, true) #, vars=nil
        end

        def reply (workitem)

            #return reply_to_parent(workitem) if @out
            #@out = true

            outcome = workitem.fields.delete 'outcome'
            outcome = outcome.to_s if outcome

            #p [ outcome, @outcomes, @default ]

            outcome = @default \
                if @outcomes and (not @outcomes.include?(outcome))

            return reply_to_parent(workitem) \
                unless outcome

            #store_itself

            template = [
                outcome.to_s, # expression name
                {}, # attributes
                [], # children
            ]

            #get_expression_pool.tlaunch_child(
            #    self, template, 1, workitem, true) #, vars=nil
            get_expression_pool.substitute_and_apply self, template, workitem
        end
    end

end

