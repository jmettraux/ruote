#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

require 'rufus/eval' # gem 'rufus-eval'

require 'openwfe/util/treechecker'
require 'openwfe/utils'
require 'openwfe/expressions/raw'


module OpenWFE

    #
    # Extend this class to create a programmatic process definition.
    #
    # A short example :
    # 
    #   class MyProcessDefinition < OpenWFE::ProcessDefinition
    #       def make
    #           process_definition :name => "test1", :revision => "0" do
    #               sequence do
    #                   set :variable => "toto", :value => "nada"
    #                   print "toto:${toto}"
    #               end
    #           end
    #       end
    #   end
    #
    #   li = OpenWFE::LaunchItem.new(MyProcessDefinition)
    #   engine.launch(li)
    # 
    #
    class ProcessDefinition

        def self.metaclass; class << self; self; end; end

        attr_reader :context

        def initialize

            super()
            @context = Context.new
        end

        def method_missing (m, *args, &block)

            #puts "__i_method_missing >>>#{m}<<<<"

            ProcessDefinition.make_expression(
                @context, 
                OpenWFE::to_expression_name(m),
                ProcessDefinition.pack_args(args), 
                &block)
        end

        def self.method_missing (m, *args, &block)

            @ccontext = Context.new \
                if (not @ccontext) or @ccontext.discarded?

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
            #attributes = OpenWFE::SymbolHash.new
            attributes = Hash.new

            #puts " ... params.class is #{params.class}"

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

            context.push_parent_expression exp

            result = block.call

            exp.last << result \
                if result and result.kind_of?(String)

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
                "process-definition", 
                { "name" => name, "revision" => revision }, 
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
        def self.eval_ruby_process_definition (code, safety_level=2)

            TreeChecker.check code

            #puts "\nin:\n#{code}\n"

            code, is_wrapped = wrap_code code

            o = Rufus::eval_safely code, safety_level, binding()

            o = extract_class(code) \
                if (o == nil) or o.is_a?(Array)
                #if (o == nil) or o.is_a?(SimpleExpRepresentation)
                    #
                    # grab the first process definition class found
                    # in the given code

            #return o.do_make \
            #    if o.is_a?(ProcessDefinition) or o.is_a?(Class)
            #o

            result = o.do_make

            #return result.first_child if is_wrapped
            return result.last.first if is_wrapped

            result
        end

        protected

            ClassNameRex = Regexp.compile(
                " *class *([a-zA-Z0-9]*) *< .*ProcessDefinition")
            ProcessDefinitionRex = Regexp.compile(
                "^class *[a-zA-Z0-9]* *< .*ProcessDefinition")
            ProcessNameAndDefRex = Regexp.compile(
                "([^0-9_]*)_*([0-9].*)$")
            ProcessNameRex = Regexp.compile(
                "(.*$)")
            EndsInDefinitionRex = Regexp.compile(
                ".*Definition$")

            def self.wrap_code (code)

                return [ code, false ] if ProcessDefinitionRex.match(code)

                s =  "class NoName0 < ProcessDefinition"
                s << "\n"
                s << code
                s << "\nend"

                [ s, true ]
            end

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

                i = s.rindex("::")
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

                s.gsub("_", ".")
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

                    return nil if @top_expressions.size > 1

                    exp = @top_expressions.first

                    return exp if exp.first == "process-definition"
                    nil
                end
            end
    end

end

