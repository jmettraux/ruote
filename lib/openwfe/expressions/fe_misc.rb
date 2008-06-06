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

#require 'rufus/eval'

require 'openwfe/expressions/flowexpression'
require 'openwfe/expressions/value'
require 'openwfe/util/treechecker'


module OpenWFE

  #
  # The 'description' expression, simply binds the given text in
  # the 'description' variable in the current process.
  #
  #   class TestDefinition2 < OpenWFE::ProcessDefinition
  #
  #     description :lang => "fr" do "rien de rien" end
  #
  #     sequence do
  #       _print "${description}"
  #       _print "${description__fr}"
  #     end
  #   end
  #
  class DescriptionExpression < FlowExpression
    include ValueMixin

    is_definition

    names :description

    DESC = 'description'


    def reply (workitem)

      lang =
        lookup_attribute(:lang, workitem) ||
        lookup_attribute(:language, workitem)

      vname = DESC
      vname += "__#{lang}" if lang

      text = lookup_attribute('text', workitem) || workitem.get_result

      set_variable(vname, text)
      set_variable(DESC, text) unless lookup_variable(DESC)
        # set default if not set

      reply_to_parent workitem
    end
  end

  #
  # A debug/test expression (it's mostly used in the test suite
  # used for the development of OpenWFEru).
  # Outputs a message to the STDOUT (via the "puts" Ruby method).
  #
  #   <print>hello</print>
  #
  #   _print "hello"
  #   _print do
  #     "in a block"
  #   end
  #
  # Note that when expressing the process in Ruby, an underscore has to be
  # placed in front of the expression name to avoid a collision with the
  # Ruby 'print' function.
  #
  # If there is an object bound in the application context under the
  # name '__tracer', this expression will append its message to this
  # instance instead of emitting to the STDOUT. (this is how the
  # OpenWFEru test suite uses this expression).
  #
  class PrintExpression < FlowExpression
    include ValueMixin

    names :print

    def reply (workitem)

      text = workitem.get_result.to_s
      text << "\n"

      tracer = @application_context['__tracer']

      if tracer
        tracer << text
      else
        puts text
      end

      reply_to_parent workitem
    end
  end

  #
  # Evals some Ruby code contained within the process definition
  # or within the workitem.
  #
  # The code is evaluated at a SAFE level of 3.
  #
  # If the :ruby_eval_allowed isn't set to true
  # (<tt>engine.application_context[:ruby_eval_allowed] = true</tt>), this
  # expression will throw an exception at apply.
  #
  # some examples :
  #
  #   <reval>
  #     workitem.customer_name = "doug"
  #     # or for short
  #     wi.customer_address = "midtown 21_21 design"
  #   </reval>
  #
  # in a Ruby process definition :
  #
  #   sequence do
  #     _set :field => "customer" do
  #       reval """
  #         {
  #           :name => "Cheezburger",
  #           :age => 34,
  #           :comment => "I can haz ?",
  #           :timestamp => Time.now.to_s
  #         }
  #       """
  #     end
  #   end
  #
  # Don't embed too much Ruby into your process definitions, it might
  # hurt...
  #
  # Reval can also be used with the 'code' attribute (or 'field-code' or
  # 'variable-code') :
  #
  #   <reval field-code="f0" />
  #
  # to eval the Ruby code held in the field named "f0".
  #
  class RevalExpression < FlowExpression
    include ValueMixin

    names :reval

    #--
    # See for an explanation on Ruby safety levels :
    # http://www.rubycentral.com/book/taint.html
    #
    # 'reval' is entitled a safe level of 3.
    #
    #SAFETY_LEVEL = 3
    #++


    def reply (workitem)

      raise "evaluation of ruby code is not allowed" \
        if @application_context[:ruby_eval_allowed] != true

      code = lookup_vf_attribute(workitem, 'code') || workitem.get_result
      code = code.to_s

      wi = workitem
        # so that the ruby code being evaluated sees 'wi' and 'workitem'

      TreeChecker.check_reval code

      #result = Rufus::eval_safely code, SAFETY_LEVEL, binding()
      result = eval code, binding()

      workitem.set_result(result) \
        if result != nil  # 'false' is a valid result

      reply_to_parent workitem
    end
  end

  #
  # An advanced expression : it takes the value in a field or variable (or
  # the nested value) and evaluates it as a process definition.
  #
  #   sequence
  #     set :field => "code", :value => "<print>hello 0</print>"
  #     _eval :field_def => "code"
  #     set :field => "code", :value => "_print 'hello 1'"
  #     _eval :field_def => "code"
  #   end
  #
  # will print "hello0\nhello1".
  #
  # This expression can be useful for evaluating process definition snippets
  # coming from participants directly.
  #
  # It's also dangerous. This 'eval' expression will raise an error if
  # the parameter :dynamic_eval_allowed in the engine's application context
  # is not set to true.
  #
  class EvalExpression < FlowExpression
    include ValueMixin

    names :eval


    def reply (workitem)

      raise "dynamic evaluation of process definitions is not allowed" \
        if @application_context[:dynamic_eval_allowed] != true

      df = lookup_vf_attribute(workitem, 'def') || workitem.get_result

      return reply_to_parent(workitem) unless df
        #
        # currently, 'nothing to eval' means, 'just go on'

      ldebug { "apply() def is >#{df}<" }

      raw_expression = build_raw_expression df

      #puts
      #puts "======================================"
      #puts raw_expression.to_s
      #puts raw_expression.raw_representation
      #puts "======================================"
      #puts

      raw_expression.apply workitem
    end

    protected

      def build_raw_expression (df)

        procdf = get_expression_pool.determine_rep df

        RawExpression.new_raw(
          fei, parent_id, environment_id, application_context, procdf)
      end
  end

  #
  # Some kind of limited 'eval' expression.
  #
  # Here is an usage example :
  #
  #   class ExampleDef < OpenWFE::ProcessDefinition
  #
  #     sequence do
  #
  #       exp :name => "p0"
  #       exp :name => "sub0"
  #
  #       exp :name => "sequence" do
  #         p0
  #         sub0
  #       end
  #
  #       set :var => "a", :value => { "ref" => "p0" }
  #       exp :name => "participant", :variable_attributes => "a"
  #     end
  #
  #     process_definition :name => "sub0" do
  #       _print "sub0"
  #     end
  #   end
  #
  # This example is a bit static, but the point is that the 'exp'
  # is extracting the real expression name (or participant or subprocess
  # name) from its 'name' attribute.
  #
  # The 'eval' expression is about evaluating a complete process definition
  # branch, 'exp' is only about one node in the process definition.
  #
  class ExpExpression < RawExpression

    names :exp

    #--
    #def initialize (fei, parent_id, env_id, app_context, att)
    #  #
    #  # this responds to the FlowExpression constructor...
    #  super fei, parent_id, env_id, app_context, nil
    #    #
    #    # but this triggers the RawExpression constructor :)
    #  @attributes = att
    #    #
    #    # as this is not done by the RawExpression constructor
    #end
    #++

    def apply (workitem)

      @applied_workitem = workitem

      super
    end

    protected

      #
      # Evaluates the 'name' attribute, if it's not present or empty,
      # will return the value for the 'default' attribute.
      #
      def expression_name

        n = lookup_attribute :name, @applied_workitem

        return lookup_attribute(:default, @applied_workitem) \
          if (not n) or (n.strip == '')

        n
      end

      #
      # If the 'attributes' attribute is present, will return its
      # value. Else, will simply return the attributes of the 'exp'
      # expression itself ('name' and 'default' included).
      #
      def extract_attributes

        att = lookup_vf_attribute @applied_workitem, :attributes
          # will currently only work with an attribute hash
          # whose keys are strings... symbols :(

        att || @attributes
      end

      #--
      #def extract_descriptions
      #  []
      #end
      #++

      def extract_children
        @children
      end

      def extract_parameters
        []
      end
  end

  #
  # This expression simply emits a message to the application
  # log (by default logs/openwferu.log).
  #
  #   <sequence>
  #     <log>before participant alpha</log>
  #     <participant ref="alpha" />
  #     <log>after participant alpha</log>
  #     <log level="warn">after participant alpha</log>
  #   </sequence>
  #
  # And an example with a Ruby process definition :
  #
  #   sequence do
  #     log "simple debug message"
  #     log do
  #       "another debug message"
  #     end
  #     log :message => "yet another debug message"
  #     log :message => "an info level message", :level => "info"
  #   end
  #
  # Possible log levels are 'debug' (the default), 'info', 'warn' and
  # 'fatal'.
  #
  class LogExpression < FlowExpression
    include ValueMixin

    names :log

    def reply (workitem)

      text = lookup_attribute('message', workitem) || workitem.get_result

      level = lookup_attribute('level', workitem)
      level = level.downcase.to_sym if level

      level = :debug \
        unless [ :info, :warn, :error, :fatal ].include?(level)

      get_engine.llog(level, text) if text

      reply_to_parent workitem
    end
  end

end

