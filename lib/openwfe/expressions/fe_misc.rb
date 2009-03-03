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

      reply_to_parent(workitem)
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

    names :print, :echo

    def reply (workitem)

      text = workitem.get_result.to_s
      text << "\n"

      tracer = @application_context['__tracer']

      if tracer
        tracer << text
      else
        puts text
      end

      reply_to_parent(workitem)
    end
  end

  #
  # Evals some Ruby code contained within the process definition
  # or within the workitem.
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
  # hurt... It's probably better to embed some ruby code in a BlockParticipant,
  # like in
  #
  #   engine.register_participant :compute_total do |workitem|
  #     sum = workitem.items.inject(0) do |sum, item|
  #       sum += item['count'] * item['price']
  #     end
  #   end
  #
  # 2 advantages : not too much ruby code in the process definition, and the
  # participant can be reused for another process.
  #
  # Reval can also be used with the 'code' attribute (or 'field-code' or
  # 'variable-code') :
  #
  #   <reval field-code="f0" />
  #
  # to eval the Ruby code held in the field named "f0".
  #
  # Note that currently, the actual evaluation of the ruby code is done in
  # the work thread, so while this ruby code is executing, there is no
  # chance for other process instances to progress. Using a block participant
  # (like explained a few paragraphs up here) avoids this problem altogether.
  #
  class RevalExpression < FlowExpression
    include ValueMixin

    names :reval


    def reply (workitem)

      raise 'evaluation of ruby code is not allowed' \
        if @application_context[:ruby_eval_allowed] != true

      code = lookup_vf_attribute(workitem, 'code') || workitem.get_result
      code = code.to_s

      wi = workitem
        # so that the ruby code being evaluated sees 'wi' and 'workitem'

      get_tree_checker.check(code)

      result = eval(code, binding())

      workitem.set_result(result) \
        if result != nil  # as 'false' is a valid result

      reply_to_parent(workitem)
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

      raise 'dynamic evaluation of process definitions is not allowed' \
        if @application_context[:dynamic_eval_allowed] != true

      df = lookup_vf_attribute(workitem, 'def') || workitem.get_result

      return reply_to_parent(workitem) unless df
        #
        # currently, 'nothing to eval' means, 'just go on'

      tree = get_def_parser.determine_rep(df)

      get_expression_pool.substitute_and_apply(self, tree, workitem)
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

      n = lookup_attribute(:name, @applied_workitem)

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

      att = lookup_vf_attribute(@applied_workitem, :attributes)
        # will currently only work with an attribute hash
        # whose keys are strings... symbols :(

      att || @attributes
    end

    def extract_children
      @children
    end

    def extract_parameters
      []
    end
  end

  #
  # This expression simply emits a message to the application
  # log (by default logs/ruote.log).
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

