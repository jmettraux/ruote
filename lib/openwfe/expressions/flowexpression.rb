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

require 'openwfe/utils'
require 'openwfe/logging'
require 'openwfe/contextual'
require 'openwfe/rudefinitions'
require 'openwfe/util/ometa'
require 'openwfe/util/dollar'


module OpenWFE

    #
    # When this variable is set to true (at the process root),
    # it means the process is paused.
    #
    VAR_PAUSED = '/__paused__'

    #
    # FlowExpression
    #
    # The base class for all OpenWFE flow expression classes.
    # It gathers all the methods for attributes and variable lookup.
    #
    class FlowExpression < ObjectWithMeta
        include Contextual, Logging, OwfeServiceLocator

        #
        # The 'flow expression id' the unique identifier within a
        # workflow instance for this expression instance.
        #
        attr_accessor :fei

        #
        # The 'flow expression id' of the parent expression.
        # Will yield 'nil' if this expression is the root of its process
        # instance.
        #
        attr_accessor :parent_id

        #
        # The 'flow expression id' of the environment this expression works
        # with.
        #
        attr_accessor :environment_id

        #
        # The attributes of the expression, as found in the process definition.
        #
        #     <participant ref='toto' timeout='1d10h' />
        #
        # The attributes will be ref => "toto" and timeout => "1d10h" (yes,
        # 'attributes' contains a hash.
        #
        attr_accessor :attributes

        #
        # An array of 'flow expression id' instances. These are the ids of
        # the expressions children to this one.
        #
        #     <sequence>
        #         <participant ref="toto" />
        #         <participant ref="bert" />
        #     </sequence>
        #
        # The expression instance for 'sequence' will hold the feis of toto and
        # bert in its children array.
        #
        attr_accessor :children

        #
        # When the FlowExpression instance is applied, this time stamp is set
        # to the current date.
        #
        attr_accessor :apply_time

        #
        # Used by raw expressions to store the not yet interpreted branches
        # of a process, used by other expressions to store their
        # representation at 'eval time'.
        #
        attr_accessor :raw_representation

        #
        # Meant to contain a boolean value. If set to 'true' it means that
        # this expression raw_representation has been modified after
        # the expression instantiation.
        #
        # It's used to keep track effectively of in-flight modifications
        # of process instances.
        #
        attr_accessor :raw_rep_updated


        #
        # The classical no-params constructors.
        #
        def initialize

            super
                #
                # very necessary as this class includes the MonitorMixin
        end

        #
        # Builds a new instance of an expression
        #
        def self.new_exp (fei, parent_id, env_id, app_context, attributes)

            e = self.new

            e.fei = fei
            e.parent_id = parent_id
            e.environment_id = env_id
            e.application_context = app_context
            e.attributes = attributes

            e.children = []
            e.apply_time = nil

            e
        end

        #--
        # the two most important methods for flow expressions
        #++

        #
        # this default implementation immediately replies to the
        # parent expression
        #
        def apply (workitem)

            get_parent.reply(workitem) if @parent_id
        end

        #
        # this default implementation immediately replies to the
        # parent expression
        #
        def reply (workitem)

            reply_to_parent workitem
        end

        #
        # Triggers the reply to the parent expression (of course, via the
        # expression pool).
        # Expressions do call this method when their job is done and the flow
        # should resume without them.
        #
        def reply_to_parent (workitem)

            get_expression_pool.reply_to_parent self, workitem
        end

        #
        # a default implementation for cancel :
        # cancels all the children
        # Attempts to return an InFlowWorkItem
        #
        def cancel

            return nil unless @children

            inflowitem = nil

            @children.each do |child|

                next if child.is_a?(String)

                i = get_expression_pool.cancel child
                inflowitem ||= i
            end

            inflowitem
        end

        #
        # some convenience methods

        #
        # Returns the parent expression (not as a FlowExpressionId but directly
        # as the FlowExpression instance it is).
        #
        def get_parent

            get_expression_pool.fetch_expression @parent_id
        end

        #
        # Stores itself in the expression pool.
        # It's very important for expressions in persisted context to save
        # themselves as soon as their state changed.
        # Else this information would be lost at engine restart or
        # simply if the expression got swapped out of memory and reloaded later.
        #
        def store_itself

            ldebug { "store_itself() for  #{@fei.to_debug_s}" }
            #ldebug { "store_itself() \n#{OpenWFE::caller_to_s(0, 6)}" }

            get_expression_pool.update self
        end

        #
        # Returns the environment instance this expression uses.
        # An environment is a container (a scope) for variables in the process
        # definition.
        # Environments themselves are FlowExpression instances.
        #
        def get_environment

            fetch_environment || get_expression_pool.fetch_engine_environment
        end

        #
        # A shortcut for fetch_environment.get_root_environment
        #
        # Returns the environment of the top process (the environement
        # just before the engine environment in the hierarchy).
        #
        def get_root_environment

            fetch_environment.get_root_environment
        end

        #
        # Just fetches the environment for this expression.
        #
        def fetch_environment

            get_expression_pool.fetch_expression @environment_id
        end

        #
        # Returns true if the expression's environment was generated
        # for itself (usually DefineExpression do have such envs)
        #
        def owns_its_environment?

            #ldebug do
            #    "owns_its_environment?()\n" +
            #    "    #{@fei.to_debug_s}\n" +
            #    "    #{@environment_id.to_debug_s}"
            #end

            return false if not @environment_id

            ei = @fei.dup
            vi = @environment_id.dup

            ei.expression_name = "neutral"
            vi.expression_name = "neutral"

            #ldebug do
            #    "owns_its_environment?()\n"+
            #    "   exp  #{ei.to_debug_s}\n"+
            #    "   env  #{vi.to_debug_s}"
            #end

            (ei == vi)
        end

        #
        # Returns true if this expression belongs to a paused flow
        #
        def paused?

            #(lookup_variable(VAR_PAUSED) == true)
            get_expression_pool.is_paused?(self)
        end

        #
        # Sets a variable in the current environment. Is usually
        # called by the 'set' expression.
        #
        # The variable name may be prefixed by / to indicate process level scope
        # or by // to indicate engine level (global) scope.
        #
        def set_variable (varname, value)

            env, var = lookup_environment(varname)

            ldebug do
                "set_variable() '#{varname}' to '#{value}' " +
                "in  #{env.fei.to_debug_s}"
            end

            env[var] = value
        end

        alias :sv :set_variable

        #
        # Looks up the value of a variable in the current environment.
        # If not found locally will lookup at the process level and even
        # further in the engine scope.
        #
        # The variable name may be prefixed by / to indicate process level scope
        # or by // to indicate engine level (global) scope.
        #
        def lookup_variable (varname)

            #puts "lv : #{varname}"
            #puts OpenWFE.caller_to_s(0, 5)

            env, var = lookup_environment varname
            env[var]
        end

        alias :lv :lookup_variable

        #
        # Unsets a variable in the current environment.
        #
        # The variable name may be prefixed by / to indicate process level scope
        # or by // to indicate engine level (global) scope.
        #
        def delete_variable (varname)

            env, var = lookup_environment varname
            env.delete var
        end

        alias :unset_variable :delete_variable

        #
        # Looks up the value for an attribute of this expression.
        #
        # if the expression is
        #
        #     <participant ref="toto" />
        #
        # then
        #
        #     participant_expression.lookup_attribute("toto", wi)
        #
        # will yield "toto"
        #
        # The various methods for looking up attributes do perform dollar
        # variable substitution.
        # It's ok to pass a Symbol for the attribute name.
        #
        def lookup_attribute (attname, workitem, options={})

            default = options[:default]
            escape = options[:escape]
            tostring = options[:to_s]

            attname = OpenWFE::symbol_to_name(attname) \
                if attname.kind_of?(Symbol)

            #ldebug { "lookup_attribute() '#{attname}' in #{@fei.to_debug_s}" }

            text = @attributes[attname]

            text = if text == nil

                default

            elsif escape == true

                text

            else

                OpenWFE::dosub text, self, workitem
            end

            text = text.to_s if text and tostring

            text
        end

        #
        # Returns the attribute value as a String (or nil if it's not found).
        #
        def lookup_string_attribute (attname, workitem, options={})

            result = lookup_attribute attname, workitem, options
            result = result.to_s if result
            result
        end

        #
        # Like lookup_attribute() but returns the value downcased [
        # (and stripped).
        # Returns nil if no such attribute was found.
        #
        def lookup_downcase_attribute (attname, workitem, options={})

            result = lookup_string_attribute attname, workitem, options
            result = result.strip.downcase if result
            result
        end

        #
        # Returns the value of the attribute as a Symbol.
        # Returns nil if there is no attribute under the given name.
        #
        def lookup_sym_attribute (attname, workitem, options={})

            result = lookup_downcase_attribute attname, workitem, options
            result = result.to_sym if result
            result
        end

        #
        # A convenience method for looking up a boolean value.
        # It's ok to pass a Symbol for the attribute name.
        #
        def lookup_boolean_attribute (attname, workitem, default=false)

            result = lookup_downcase_attribute attname, workitem
            return default if result == nil

            (result == 'true')
        end

        #
        # looks up an attribute, if it's an array, returns it. Else
        # (probably a string) will split it (comma) and return it
        # (each element trimmed).
        #
        def lookup_array_attribute (attname, workitem, options={})

            tostring = options.delete :to_s

            v = lookup_attribute attname, workitem, options

            return nil unless v

            v = v.to_s.split(",").collect { |e| e.strip } \
                unless v.is_a?(Array)

            v = v.collect { |e| e.to_s } \
                if tostring

            v
        end

        #
        # Returns true if the expression has the given attribute.
        # The attname parameter can be a String or a Symbol.
        #
        def has_attribute (attname)

            attname = OpenWFE::symbol_to_name(attname) \
                if attname.kind_of?(Symbol)

            (@attributes[attname] != nil)
        end

        #
        # Returns a hash of all the FlowExpression attributes with their
        # values having undergone dollar variable substitution.
        # If the _attributes parameter is set (to an Array instance) then
        # only the attributes named in that list will be looked up.
        #
        # It's ok to pass an array of Symbol instances for the attributes
        # parameter.
        #
        def lookup_attributes (workitem, _attributes=nil)

            return {} unless @attributes

            (_attributes || @attributes.keys).inject({}) do |r, k|

                k = k.to_s
                v = @attributes[k]

                r[k] = OpenWFE::dosub v, self, workitem

                r
            end
        end

        #
        # creates a new environment just for this expression
        #
        def new_environment (initial_vars=nil)

            ldebug { "new_environment() for #{@fei.to_debug_s}" }

            @environment_id = @fei.dup
            @environment_id.expression_name = EN_ENVIRONMENT

            parent_fei = nil
            parent = nil

            parent, _fei = get_expression_pool.fetch(@parent_id) \
                if @parent_id

            parent_fei = parent.environment_id if parent

            env = Environment.new_env(
                @environment_id, parent_fei, nil, @application_context, nil)

            env.variables.merge! initial_vars if initial_vars

            env[@fei.wfname] = self.raw_representation \
                if (not @parent_id) and (self.is_a?(RawExpression))
                    #
                    # keeping track of the raw representation
                    # of the top expression (for top recursion)

            ldebug { "new_environment() is #{env.fei.to_debug_s}" }

            env.store_itself

            env
        end

        #
        # This method is called in expressionpool.forget(). It duplicates
        # the expression's current environment (deep copy) and attaches
        # it as the expression own environment.
        # Returns the duplicated environment.
        #
        def dup_environment

            env = fetch_environment
            env = env.dup
            env.fei = @fei.dup
            env.fei.expression_name = EN_ENVIRONMENT
            @environment_id = env.fei

            env.store_itself
        end

        #
        # Takes care of removing all the children of this expression, if any.
        #
        def clean_children

            return unless @children

            @children.each do |child_fei|
                get_expression_pool.remove(child_fei) \
                    if child_fei.kind_of?(FlowExpressionId)
            end
        end

        #
        # Removes a child from the expression children list.
        #
        def remove_child (child_fei)

            #fei = @children.delete child_fei
            #store_itself if fei

            i = @children.index child_fei

            return unless i

            @children.delete_at i
            raw_children.delete_at i
            @raw_rep_updated = true

            store_itself
        end

        #
        # Currently only used by dollar.rb and its ${r:some_ruby_code},
        # returns the binding in this flow expression.
        #
        def get_binding

            binding()
        end

        #--
        # Used like the classical Ruby synchronize, but as the OpenWFE
        # expression pool manages its own set of monitors, it's one of those
        # monitors that is used. But the synchronize code looks like the class
        # just included the MonitorMixin. No hassle.
        #
        #def synchronize
        #    #ldebug { "synchronize() ---in--- for  #{@fei.to_debug_s}" }
        #    get_expression_pool.get_monitor(@fei).synchronize do
        #        yield
        #    end
        #    #ldebug { "synchronize() --out--  for  #{@fei.to_debug_s}" }
        #end
        #++

        #
        # Returns the text stored among the children
        #
        def fetch_text_content (workitem, escape=false)

            cs = children || raw_children

            text = cs.inject("") do |r, child|

                if child.is_a?(RawExpression)

                    r << child.fei.to_s

                elsif child.is_a?(FlowExpressionId)

                    r << get_expression_pool\
                        .fetch_expression(child).raw_representation.to_s

                else

                    r << child.to_s
                end
            end

            return nil if text == ""

            text = OpenWFE::dosub(text, self, workitem) \
                unless escape

            text
        end

        #
        # looks up for 'value', 'variable-value' and then for 'field-value'
        # if necessary.
        #
        def lookup_value (workitem, options={})

            lookup_vf_attribute(workitem, 'value', options) ||
            lookup_vf_attribute(workitem, 'val', options)
        end

        #
        # looks up for 'ref', 'variable-ref' and then for 'field-ref'
        # if necessary.
        #
        def lookup_ref (workitem, prefix='')

            ref = lookup_vf_attribute workitem, 'ref', :prefix => prefix
            return ref.to_s if ref
            nil
        end

        #
        # Looks up for value attributes like 'field-ref' or 'variable-value'
        #
        def lookup_vf_attribute (workitem, att_name, options={})

            att_name = att_name.to_s

            prefix = options[:prefix] || ''
            prefix = prefix.to_s

            dash = (att_name.size > 0 and prefix.size > 0) ? "-" : ""

            v = lookup_attribute(
                "#{prefix}#{dash}#{att_name}", workitem, options)

            att_name = "-#{att_name}" if att_name.size > 0
            prefix = "#{prefix}-" if prefix.size > 0

            return v if v

            v = lookup_attribute(
                "#{prefix}variable#{att_name}", workitem, options) ||
                lookup_attribute(
                "#{prefix}var#{att_name}", workitem, options) ||
                lookup_attribute(
                "#{prefix}v#{att_name}", workitem, options)

            return lookup_variable(v) if v

            f = lookup_attribute(
                "#{prefix}field#{att_name}", workitem, options) ||
                lookup_attribute(
                "#{prefix}f#{att_name}", workitem, options)

            #return workitem.attributes[f] if f
            return workitem.attributes[f.to_s] if f

            nil
        end

        #
        # Since OpenWFEru 0.9.17, each expression keeps his @raw_representation
        # this is a shortcut for exp.raw_representation[2]
        #
        def raw_children

            @raw_representation[2]
        end

        SUBIDMUTEX = Mutex.new

        #
        # Returns the next sub process id available (this counter
        # is stored in the process environment under the key :next_sub_id)
        #
        def get_next_sub_id

            #env = get_environment
            env = get_root_environment

            c = nil

            #env.synchronize do

            c = env.variables[:next_sub_id]
            n = if c
                c + 1
            else
                c = 0
                1
            end
            env.variables[:next_sub_id] = n
            env.store_itself
            #end

            c
        end

        #
        # Some eye candy
        #
        def to_s

            s =    "* #{@fei.to_debug_s} [#{self.class.name}]"

            s << "\n   `--p--> #{@parent_id.to_debug_s}" \
                if @parent_id

            s << "\n   `--e--> #{@environment_id.to_debug_s}" \
                if @environment_id

            return s unless @children

            @children.each do |c|
                sc = if c.kind_of?(OpenWFE::FlowExpressionId)
                    c.to_debug_s
                else
                    ">#{c.to_s}<"
                end
                s << "\n   `--c--> #{sc}"
            end

            s
        end

        #
        # a nice 'names' tag/method for registering the names of the
        # Expression classes.
        #
        def self.names (*exp_names)

            exp_names = exp_names.collect do |n|
                n.to_s
            end
            meta_def :expression_names do
                exp_names
            end
        end

        #
        # returns true if the expression class is a 'definition'.
        #
        def self.is_definition?
            false
        end
        def self.is_definition
            meta_def :is_definition? do
                true
            end
        end

        #
        # returns true if the expression class 'uses a template'
        # (children will not immediately get expanded at 'parse' time)
        #
        def self.uses_template?
            false
        end
        def self.uses_template
            meta_def :uses_template? do
                true
            end
        end

        protected

            #
            # If the varname starts with '//' will return the engine
            # environment and the truncated varname...
            # If the varname starts with '/' will return the root environment
            # for the current process instance and the truncated varname...
            #
            def lookup_environment (varname)

                if varname[0, 2] == '//'
                    return [
                        get_expression_pool.fetch_engine_environment,
                        varname[2..-1]
                    ]
                end

                if varname[0, 1] == '/'
                    return [
                        get_environment.get_root_environment,
                        varname[1..-1]
                    ]
                end

                [ get_environment, varname ]
            end
    end

end

