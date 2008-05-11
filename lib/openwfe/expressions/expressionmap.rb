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

require 'openwfe/expressions/raw'
require 'openwfe/expressions/environment'
require 'openwfe/expressions/fe_define'
require 'openwfe/expressions/fe_misc'
require 'openwfe/expressions/fe_set'
require 'openwfe/expressions/fe_if'
require 'openwfe/expressions/fe_equals'
require 'openwfe/expressions/fe_sequence'
require 'openwfe/expressions/fe_subprocess'
require 'openwfe/expressions/fe_concurrence'
require 'openwfe/expressions/fe_participant'
require 'openwfe/expressions/fe_sleep'
require 'openwfe/expressions/fe_cron'
require 'openwfe/expressions/fe_when'
require 'openwfe/expressions/fe_wait'
require 'openwfe/expressions/fe_reserve'
require 'openwfe/expressions/fe_losfor'
require 'openwfe/expressions/fe_command'
require 'openwfe/expressions/fe_cursor'
require 'openwfe/expressions/fe_iterator'
require 'openwfe/expressions/fe_fqv'
require 'openwfe/expressions/fe_cancel'
require 'openwfe/expressions/fe_do'
require 'openwfe/expressions/fe_save'
require 'openwfe/expressions/fe_filter_definition'
require 'openwfe/expressions/fe_filter'
require 'openwfe/expressions/fe_listen'
require 'openwfe/expressions/fe_timeout'
require 'openwfe/expressions/fe_step'


module OpenWFE

    #
    # The mapping between expression names like 'sequence', 'participant', etc
    # and classes like 'ParticipantExpression', 'SequenceExpression', etc.
    #
    class ExpressionMap

        def initialize

            super

            @expressions = {}
            @ancestors = {}

            register DefineExpression

            register SequenceExpression
            register ParticipantExpression

            register ConcurrenceExpression
            register GenericSyncExpression

            register ConcurrentIteratorExpression

            register SubProcessRefExpression

            register SetValueExpression
            register UnsetValueExpression

            register DefinedExpression

            register IfExpression
            register CaseExpression

            register EqualsExpression

            register SleepExpression
            register CronExpression
            register WhenExpression
            register WaitExpression

            register ReserveExpression

            register RevalExpression
            register PrintExpression
            register LogExpression

            register LoseExpression
            register ForgetExpression

            register CursorExpression
            register LoopExpression

            register CursorCommandExpression

            register IteratorExpression

            register FqvExpression
            register AttributeExpression

            register CancelProcessExpression

            register UndoExpression
            register RedoExpression

            register SaveWorkItemExpression
            register RestoreWorkItemExpression

            register FilterDefinitionExpression
            register FilterExpression

            register ListenExpression

            register TimeoutExpression

            register EvalExpression
            register ExpExpression

            register StepExpression

            register Environment
                #
                # only used by get_expression_names()

            register_ancestors RawExpression
            #register_ancestors XmlRawExpression
            #register_ancestors ProgRawExpression
                #
                # just register the ancestors for those two
        end

        #
        # Returns the expression class corresponding to the given 
        # expression name
        #
        def get_class (expression_name)

            expression_name = expression_name.expression_name \
                if expression_name.kind_of?(RawExpression)

            expression_name = OpenWFE::symbol_to_name(expression_name)

            @expressions[expression_name]
        end

        def get_sync_class (expression_name)

            get_class(expression_name)
        end

        #
        # Returns true if the given expression name ('sequence', 
        # 'process-definition', ...) is a DefineExpression.
        #
        def is_definition? (expression_name)

            c = get_class(expression_name)

            #c == DefineExpression
            (c and c.is_definition?)
        end

        #
        # Returns an array of expression names whose class are assignable
        # from the given expression_class.
        #
        def get_expression_names (expression_class)

            return expression_class.expression_names \
                if expression_class.method_defined?(:expression_names)

            names = []
            @expressions.each do |k, v|
                names << k if v.ancestors.include? expression_class
            end
            names
        end

        #
        # Returns an array of expression classes that have the given 
        # class/module among their ancestors.
        #
        def get_expression_classes (ancestor)

            @ancestors[ancestor]
        end

        def to_s
            s = ""
            @expressions.keys.sort.each do |name|
                s << "- '#{name}' -> '#{@expressions[name].to_s}'\n"
            end
            s
        end

        #
        # Registers an Expression class within this expression map.
        # This method is usually never called from out of the ExpressionMap
        # class, but, who knows, it could prove useful one day as a 'public'
        # method.
        #
        def register (expression_class)

            expression_class.expression_names.each do |name|
                name = OpenWFE::to_dash(name)
                @expressions[name] = expression_class
            end
            register_ancestors expression_class
        end

        protected

            #
            # registers all the ancestors of an expression class
            #
            def register_ancestors (expression_class)

                expression_class.ancestors.each do |ancestor|
                    (@ancestors[ancestor] ||= []) << expression_class
                end
            end
    end

end

