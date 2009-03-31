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
require 'openwfe/expressions/fe_error'
require 'openwfe/expressions/fe_save'
require 'openwfe/expressions/fe_filter_definition'
require 'openwfe/expressions/fe_filter'
require 'openwfe/expressions/fe_listen'
require 'openwfe/expressions/fe_timeout'
require 'openwfe/expressions/fe_step'
require 'openwfe/expressions/fe_http'


module OpenWFE

  #
  # The mapping between expression names like 'sequence', 'participant', etc
  # and classes like 'ParticipantExpression', 'SequenceExpression', etc.
  #
  class ExpressionMap

    #
    # the list of expression classes that may hold a workitem
    # (for example, 'wait', 'listen' and more importantly 'participant').
    #
    attr_reader :workitem_holders

    #
    # Instantiates this expression map (1 per engine).
    #
    def initialize

      #super

      @expressions = {}
      @ancestors = {}
      @workitem_holders = []

      register DefineExpression

      register DescriptionExpression

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

      register ErrorExpression

      register SaveWorkItemExpression
      register RestoreWorkItemExpression

      register FilterDefinitionExpression
      register FilterExpression

      register ListenExpression

      register TimeoutExpression

      register EvalExpression
      register ExpExpression

      register StepExpression

      register HttpExpression
      register HpollExpression

      register Environment
        #
        # only used by get_expression_names()

      register_ancestors RawExpression
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

      (c and c.is_definition?)
    end

    #
    # Returns an array of expression names whose class are assignable
    # from the given expression_class.
    #
    def get_expression_names (expression_class)

      return expression_class.expression_names \
        if expression_class.method_defined?(:expression_names)

      @expressions.inject([]) do |names, (k, v)|
        names << k if v.ancestors.include?(expression_class)
        names
      end
    end

    #
    # Returns an array of expression classes that have the given
    # class/module among their ancestors.
    #
    def get_expression_classes (ancestor)

      @ancestors[ancestor]
    end

    #
    # Returns a string representation for this expression map.
    #
    def to_s

      @expressions.keys.sort.inject('') do |s, name|
        s << "- '#{name}' -> '#{@expressions[name].to_s}'\n"; s
      end
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

      if expression_class.public_instance_methods.find { |fn|
        fn.to_s == 'applied_workitem'
      }
        @workitem_holders << expression_class
      end

      register_ancestors(expression_class)
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

