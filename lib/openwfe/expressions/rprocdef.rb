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


require 'openwfe/util/treechecker'
require 'openwfe/utils'
require 'openwfe/expressions/raw'


module OpenWFE

  #
  # A shorthand for writing process definitions like :
  #
  #   Test2 = OpenWFE.process_definition :name => 'ft_11b', :revision => '2' do
  #     sequence do
  #       participant 'alpha'
  #       sleep '3d'
  #       participant 'bravo'
  #     end
  #   end
  #
  # This will store in the constant Test2 the process definition in its
  # 'raw' (tree) form :
  #
  #   ["process-definition", {"name"=>"ft_11b", "revision"=>"2"}, [
  #     ["sequence", {}, [
  #       ["participant", {}, ["alpha"]],
  #       ["sleep", {}, ["3d"]],
  #       ["participant", {}, ["bravo"]]]]]]
  #
  def self.process_definition (*args, &block)

    pd = ProcessDefinition.new
    pd.instance_eval(&block)

    [
      'process-definition',
      lambda() { |a|
        atts = a.last.is_a?(Hash) ? a.last : {}
        atts['name'] = a.first unless a.first.is_a?(Hash)
        atts.inject({}) { |h, (k, v)| h[OpenWFE.symbol_to_name(k)] = v; h }
      }.call(args),
      #[ ProcessDefinition.new.instance_eval(&block) ]
      pd.context.top_expressions
    ]
  end

  #
  # Extend this class to create a programmatic process definition.
  #
  # A short example :
  #
  #   class MyProcessDefinition < OpenWFE::ProcessDefinition
  #     process_definition :name => "test1", :revision => "0" do
  #       sequence do
  #         set :variable => "toto", :value => "nada"
  #         echo "toto:${toto}"
  #       end
  #     end
  #   end
  #
  #   li = OpenWFE::LaunchItem.new(MyProcessDefinition)
  #   engine.launch(li)
  #
  class ProcessDefinition

    def self.metaclass; class << self; self; end; end

    attr_reader :context

    def initialize

      super()
      @context = Context.new
    end

    def method_missing (m, *args, &block)

      #p [ :method_missing, m ]

      return nil if m == :make

      ProcessDefinition.make_expression(
        @context,
        OpenWFE::to_expression_name(m),
        ProcessDefinition.pack_args(args),
        &block)
    end

    def self.method_missing (m, *args, &block)

      @ccontext = Context.new if (not @ccontext) or @ccontext.discarded?

      ProcessDefinition.make_expression(
        @ccontext,
        OpenWFE::to_expression_name(m),
        ProcessDefinition.pack_args(args),
        &block)
    end

    #
    # builds an actual expression representation (a node in the
    # process definition tree).
    #
    def self.make_expression (context, exp_name, params, &block)

      string_child = nil
      attributes = Hash.new

      if params.kind_of?(Hash)

        params.each do |k, v|

          if k == '0'
            string_child = v.to_s
          else
            #attributes[OpenWFE::symbol_to_name(k.to_s)] = v.to_s
            attributes[OpenWFE::symbol_to_name(k.to_s)] = v
          end
        end

      elsif params

        string_child = params.to_s
      end

      exp = [ exp_name, attributes, [] ]

      exp.last << string_child \
        if string_child

      if context.parent_expression
        #
        # adding this new expression to its parent
        #
        context.parent_expression.last << exp
      else
        #
        # an orphan, a top expression
        #
        context.top_expressions << exp
      end

      return exp unless block

      context.push_parent_expression(exp)

      result = block.call

      exp.last << result if result and result.is_a?(String)

      context.pop_parent_expression

      exp
    end

    def do_make

      ProcessDefinition.do_make self
    end

    #
    # A class method for actually "making" the process
    # segment raw representation
    #
    def self.do_make (instance=nil)

      context = if @ccontext

        @ccontext.discard
          # preventing further additions in case of reevaluation
        @ccontext

      elsif instance

        instance.make
        instance.context

      else

        pdef = self.new
        pdef.make
        pdef.context
      end

      return context.top_expression if context.top_expression

      name, revision =
        extract_name_and_revision(self.metaclass.to_s[8..-2])

      top_expression = [
        'process-definition',
        { 'name' => name, 'revision' => revision },
        context.top_expressions
      ]

      top_expression
    end

    #
    # Parses the string to find the class name of the process definition
    # and returns that class (instance).
    #
    def self.extract_class (ruby_proc_def_string)

      ruby_proc_def_string.each_line do |l|

        m = ClassNameRex.match l

        return eval(m[1]) if m
      end

      nil
    end

    #
    # Turns a String containing a ProcessDefinition ...
    #
    def self.eval_ruby_process_definition (code)

      #TreeChecker.check code
        #
        # checks for 'illicit' ruby code before the eval
        # (now done in the DefParser)

      o = eval(code, binding())

      klass = extract_class(code)
        #
        # grab the first process definition class found
        # in the given code

      return o unless klass

      klass.do_make
    end

    protected

      ClassNameRex = Regexp.compile(
        " *class *([a-zA-Z0-9]*) *< .*ProcessDefinition")
      #ProcessDefinitionRex = Regexp.compile(
      #  "^class *[a-zA-Z0-9]* *< .*ProcessDefinition")
      ProcessNameAndDefRex = Regexp.compile(
        "([^0-9_]*)_*([0-9].*)$")
      ProcessNameRex = Regexp.compile(
        "(.*$)")
      EndsInDefinitionRex = Regexp.compile(
        ".*Definition$")

      def self.pack_args (args)

        return args[0] if args.length == 1

        a = {}
        args.each_with_index do |arg, index|
          if arg.is_a?(Hash)
            a = a.merge(arg)
            break
          end
          a[index.to_s] = arg
        end
        a
      end

      def self.extract_name_and_revision (s)

        i = s.rindex('::')
        s = s[i+2..-1] if i

        m = ProcessNameAndDefRex.match s
        return [ as_name(m[1]), as_revision(m[2]) ] if m

        m = ProcessNameRex.match s
        return [ as_name(m[1]), '0' ] if m

        [ as_name(s), '0' ]
      end

      def self.as_name (s)

        return s[0..-11] if EndsInDefinitionRex.match(s)
        s
      end

      def self.as_revision (s)

        s.gsub('_', '.')
      end

      class Context

        attr_accessor :parent_expression, :top_expressions
        attr_reader :previous_parent_expressions

        def initialize
          @parent_expression = nil
          @top_expressions = []
          @previous_parent_expressions = []
        end

        def discard
          @discarded = true
        end
        def discarded?
          (@discarded == true)
        end

        #
        # puts the current parent expression on top of the 'previous
        # parent expressions' stack, the current parent expression
        # is replaced with the supplied parent expression.
        #
        def push_parent_expression (exp)

          @previous_parent_expressions.push(@parent_expression) \
            if @parent_expression

          @parent_expression = exp
        end

        #
        # Replaces the current parent expression with the one found
        # on the top of the previous parent expression stack (pop).
        #
        def pop_parent_expression

          @parent_expression = @previous_parent_expressions.pop
        end

        #
        # This method returns the top expression among the
        # top expressions...
        #
        def top_expression

          exp = @top_expressions.first

          return nil unless exp

          exp_name = OpenWFE::to_underscore(exp[0])

          DefineExpression.expression_names.include?(exp_name) ? exp : nil
        end
      end
  end

end

