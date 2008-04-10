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
    class DefineExpression < SequenceExpression

        is_definition

        names :define, :process_definition, :workflow_definition

        #
        # A pointer to the body expression of this process definition.
        #
        attr_accessor :body_fei

        #--
        # Evaluates the definition, but doesn't apply its body, will 
        # simply return the body fei.
        #
        #def evaluate (workitem)
        #    @eval_only = true
        #    apply workitem
        #    @body_fei
        #end
        #++

        #
        # Called at the end of the 'evaluation', the 'apply' operation on
        # the body of the definition is done here.
        #
        def reply_to_parent (workitem)

            #return if @eval_only

            #puts "/// \n   bf #{@body_fei} \n   wi.fei #{workitem.fei}"

            return super(workitem) \
                if @body_fei == nil or @body_fei == workitem.fei
                #unless @body_fei

            #_fei = @body_fei
            #@body_fei = nil
            #store_itself
            #get_expression_pool.apply _fei, workitem

            get_expression_pool.apply @body_fei, workitem
        end

        #
        # Overrides the set_variable in FlowExpression to
        # make sure to intercept requests for binding subprocesses
        # at the engine level and to store a copy of the raw expression,
        # not only the flow expression id.
        #
        def set_variable (name, fei)

            if name[0, 2] == "//"

                raw_exp = get_expression_pool.fetch_expression(fei).dup
                raw_exp.parent_id = nil
                raw_exp.fei = raw_exp.fei.dup
                fei = raw_exp.fei
                fei.wfid = get_wfid_generator.generate 

                raw_exp.store_itself
            end

            super name, fei
        end

        protected

            #
            # Determines the flowExpressionId of the next child to apply.
            #
            def next_child (current_fei)

                next_fei = super

                return nil unless next_fei

                rawchild = get_expression_pool.fetch_expression next_fei

                return next_child(next_fei) unless rawchild

                unless rawchild.is_definition?

                    unless @body_fei
                        @body_fei = next_fei
                        store_itself
                    end
                    return next_child(next_fei)
                end

                exp_class = get_expression_map.get_class rawchild

                if exp_class == DefineExpression
                    set_variable rawchild.definition_name, next_fei
                    return next_child(next_fei)
                end

                next_fei
                    #
                    # expression is a 'set', a 'filter-definition' or
                    # something like that, let it get applied
            end
    end

end

