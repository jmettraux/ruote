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

require 'openwfe/utils'
require 'openwfe/logging'
require 'openwfe/contextual'
require 'openwfe/rudefinitions'
require 'openwfe/util/ometa'
require 'openwfe/util/dollar'
require 'openwfe/expressions/expression_tree'


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

    include Contextual
    include Logging
    include OwfeServiceLocator

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
    #   <participant ref='toto' timeout='1d10h' />
    #
    # The attributes will be ref => "toto" and timeout => "1d10h" (yes,
    # 'attributes' contains a hash.
    #
    attr_accessor :attributes

    #
    # An array of 'flow expression id' instances. These are the ids of
    # the expressions children to this one.
    #
    #   <sequence>
    #     <participant ref="toto" />
    #     <participant ref="bert" />
    #   </sequence>
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
    # When was this expression last updated ?
    #
    attr_accessor :updated_at


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

      reply_to_parent(workitem)
    end

    #
    # Triggers the reply to the parent expression (of course, via the
    # expression pool).
    # Expressions do call this method when their job is done and the flow
    # should resume without them.
    #
    def reply_to_parent (workitem)

      get_expression_pool.reply_to_parent(self, workitem)
    end

    #
    # A default implementation for cancel :
    # triggers any registered 'on_cancel' and then cancels all the children
    #
    # Attempts to return an InFlowWorkItem
    #
    def cancel

      trigger_on_cancel

      (@children || []).inject(nil) do |workitem, child|

        #wi = child.is_a?(String) ? nil : get_expression_pool.cancel(child)
        wi = get_expression_pool.cancel(child)
        workitem ||= wi
      end
    end

    #
    # triggers the on_cancel attribute of the expression, if any, and forgets
    # it...
    #
    # makes sure to pass a copy of the cancelled process's variables to the
    # on_cancel process/participant if any
    #
    def trigger_on_cancel

      on_cancel = (self.attributes || {})['on_cancel'] || return

      on_cancel, workitem = on_cancel

      template = lookup_variable(on_cancel) || [ on_cancel, {}, [] ]

      get_expression_pool.launch_subprocess(
        self,template, true, workitem, get_environment.lookup_all_variables)
    end

    #
    # some convenience methods

    #
    # Returns the parent expression (not as a FlowExpressionId but directly
    # as the FlowExpression instance it is).
    #
    def get_parent

      get_expression_pool.fetch_expression(@parent_id)
    end

    #
    # Stores itself in the expression pool.
    # It's very important for expressions in persisted context to save
    # themselves as soon as their state changed.
    # Else this information would be lost at engine restart or
    # simply if the expression got swapped out of memory and reloaded later.
    #
    def store_itself

      #ldebug { "store_itself() for  #{@fei.to_debug_s}" }
      #ldebug { "store_itself() \n#{OpenWFE::caller_to_s(0, 6)}" }

      get_expression_pool.update(self)
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

      get_expression_pool.fetch_expression(@environment_id)
    end

    #
    # Returns true if the expression's environment was generated
    # for itself (usually DefineExpression do have such envs)
    #
    def owns_its_environment?

      return false if not @environment_id

      ei = @fei.dup
      vi = @environment_id.dup

      ei.expression_name = 'neutral'
      vi.expression_name = 'neutral'

      (ei == vi)
    end

    #
    # Returns true if this expression belongs to a paused flow
    #
    def paused?

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

      env, var = lookup_environment(varname)
      env[var]
    end

    alias :lv :lookup_variable

    #
    # Returns a stack of variable values, from here down to the engine
    # environment.
    #
    # A stack is simply an array whose first value is the local value and
    # the last value, the value registered in the engine env (if any is
    # registered there).
    #
    def lookup_variable_stack (varname)

      get_environment.lookup_variable_stack(varname)
    end

    #
    # Unsets a variable in the current environment.
    #
    # The variable name may be prefixed by / to indicate process level scope
    # or by // to indicate engine level (global) scope.
    #
    def delete_variable (varname)

      env, var = lookup_environment(varname)
      env.delete(var)
    end

    alias :unset_variable :delete_variable

    #
    # Looks up the value for an attribute of this expression.
    #
    # if the expression is
    #
    #   <participant ref="toto" />
    #
    # then
    #
    #   participant_expression.lookup_attribute("toto", wi)
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

      attname = OpenWFE.symbol_to_name(attname) if attname.kind_of?(Symbol)

      text = @attributes[attname]

      text = if text == nil

        default

      elsif escape == true

        text

      else

        OpenWFE.dosub(text, self, workitem)
      end

      text = text.to_s if text and tostring

      text
    end

    #
    # Returns the attribute value as a String (or nil if it's not found).
    #
    def lookup_string_attribute (attname, workitem, options={})

      result = lookup_attribute(attname, workitem, options)
      result = result.to_s if result
      result
    end

    #
    # Like lookup_attribute() but returns the value downcased [
    # (and stripped).
    # Returns nil if no such attribute was found.
    #
    def lookup_downcase_attribute (attname, workitem, options={})

      result = lookup_string_attribute(attname, workitem, options)
      result = result.strip.downcase if result
      result
    end

    #
    # Returns the value of the attribute as a Symbol.
    # Returns nil if there is no attribute under the given name.
    #
    def lookup_sym_attribute (attname, workitem, options={})

      result = lookup_downcase_attribute(attname, workitem, options)
      result = result.to_sym if result
      result
    end

    #
    # A convenience method for looking up a boolean value.
    # It's ok to pass a Symbol for the attribute name.
    #
    def lookup_boolean_attribute (attname, workitem, default=false)

      result = lookup_downcase_attribute(attname, workitem)
      return default if result == nil

      (result == 'true')
    end

    #
    # looks up an attribute, if it's an array, returns it. Else
    # (probably a string) will split it (comma) and return it
    # (each element trimmed).
    #
    def lookup_array_attribute (attname, workitem, options={})

      tostring = options.delete(:to_s)

      v = lookup_attribute(attname, workitem, options)

      return nil unless v

      v = v.to_s.split(',').collect { |e| e.strip } \
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

      attname = OpenWFE::symbol_to_name(attname) if attname.is_a?(Symbol)

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

      @environment_id = @fei.dup
      @environment_id.expression_name = EN_ENVIRONMENT

      parent_fei = nil
      parent = nil

      parent, _fei = get_expression_pool.fetch(@parent_id) \
        if @parent_id

      parent_fei = parent.environment_id if parent

      env = Environment.new_env(
        @environment_id, parent_fei, nil, @application_context, nil)

      env.variables.merge!(initial_vars) if initial_vars

      env[@fei.wfname] = self.raw_representation \
        if (not @parent_id) and (self.is_a?(RawExpression))
          #
          # keeping track of the raw representation
          # of the top expression (for top recursion)

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
        #next unless child.is_a?(FlowExpressionId)
        get_expression_pool.remove(child_fei)
      end
    end

    #
    # Removes a child from the expression children list.
    #
    def remove_child (child_fei)

      i = @children.index(child_fei)

      return unless i

      @children.delete_at(i)
      raw_children.delete_at(i)
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

    #
    # Returns the text stored among the children
    #
    def fetch_text_content (workitem, escape=false)

      text = (children || raw_children).inject('') do |r, child|

        r << child.to_s
      end

      return nil if text == ''

      escape ? text : OpenWFE::dosub(text, self, workitem)
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

      ref = lookup_vf_attribute(workitem, 'ref', :prefix => prefix)
      ref ? ref.to_s : nil
    end

    #
    # Looks up for value attributes like 'field-ref' or 'variable-value'
    #
    def lookup_vf_attribute (workitem, att_name, options={})

      att_name = att_name.to_s

      prefix = options[:prefix] || ''
      prefix = prefix.to_s

      dash = (att_name.size > 0 and prefix.size > 0) ? '-' : ''

      v = lookup_attribute("#{prefix}#{dash}#{att_name}", workitem, options)

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

      f ? workitem.attributes[f.to_s] : nil
    end

    #
    # Since OpenWFEru 0.9.17, each expression keeps his @raw_representation
    # this is a shortcut for exp.raw_representation[2]
    #
    def raw_children

      @raw_representation[2]
    end

    #
    # Returns a list of children that are expressions (arrays)
    #
    def raw_expression_children

      @raw_representation[2].select { |c| c.is_a?(Array) }
    end

    #
    # Returns true if the current expression has no expression among its
    # [raw] children.
    #
    def has_no_expression_child

      (first_expression_child == nil)
    end

    #
    # Returns the index of the first child that is an expression.
    #
    def first_expression_child

      @raw_representation[2].find { |c| c.is_a?(Array) }
    end

    #
    # Returns the next sub process id available (this counter
    # is stored in the process environment under the key :next_sub_id)
    #
    def get_next_sub_id

      env = get_root_environment

      c = nil

      c = env.variables[:next_sub_id]
      n = if c
        c + 1
      else
        c = 0
        1
      end
      env.variables[:next_sub_id] = n
      env.store_itself

      c
    end

    #
    # Given a child index (in the raw_children list/array), applies that
    # child.
    #
    # Does the bulk work of preparing the children and applying it (also
    # cares about registering the child in the @children array).
    #
    def apply_child (child_index, workitem)

      child_index, child = if child_index.is_a?(Integer)
        [ child_index, raw_children[child_index] ]
      else
        [ raw_children.index(child_index), child_index ]
      end

      get_expression_pool.tlaunch_child(
        self, child, child_index, workitem, :register_child => true)
    end

    #
    # Some eye candy
    #
    def to_s

      s =  "* #{@fei.to_debug_s} [#{self.class.name}]"

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
    # Returns true if the expression class is a 'definition'.
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
    # Returns true if the expression with the given fei is an ancestor
    # of this expression.
    #
    def descendant_of? (fei)

      #p [ :d_of?, "#{@fei.wfid} #{@fei.expid}", "#{fei.wfid} #{fei.expid}" ]

      return false if @parent_id == nil
      return true if @parent_id == fei
      return true if fei.ancestor_of?(@fei) # shortcut

      get_expression_pool.fetch_expression(@parent_id).descendant_of?(fei)
    end

    def marshal_dump #:nodoc#
      iv = instance_variables
      iv.delete('@application_context')
      iv.inject({}) { |h, vn| h[vn] = instance_variable_get(vn); h }
    end

    def marshal_load (s) #:nodoc#
      s.each { |k, v| instance_variable_set(k, v) }
    end

    def to_yaml_properties #:nodoc#
      l = super
      l.delete('@application_context')
      l
    end

    protected

    #
    # Initializes the @children member array.
    #
    # Used by 'concurrence' for example.
    #
    def extract_children
      i = 0
      @children = []
      raw_representation.last.each do |child|
        if OpenWFE::ExpressionTree.is_not_a_node?(child)
          @children << child
        else
          cname = child.first.intern
          next if cname == :param
          next if cname == :parameter
          #next if cname == :description
          cfei = @fei.dup
          cfei.expression_name = child.first
          cfei.expression_id = "#{cfei.expression_id}.#{i}"
          efei = @environment_id
          rawexp = RawExpression.new_raw(
            cfei, @fei, efei, @application_context, OpenWFE::fulldup(child))
          get_expression_pool.update(rawexp)
          i += 1
          @children << rawexp.fei
        end
      end
    end

    #
    # If the varname starts with '//' will return the engine
    # environment and the truncated varname...
    # If the varname starts with '/' will return the root environment
    # for the current process instance and the truncated varname...
    #
    def lookup_environment (varname)

      return [
        get_expression_pool.fetch_engine_environment, varname[2..-1]
      ] if varname[0, 2] == '//'

      return [
        get_environment.get_root_environment, varname[1..-1]
      ] if varname[0, 1] == '/'

      [ get_environment, varname ]
    end
  end

end

