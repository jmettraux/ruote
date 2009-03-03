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


require 'rufus/scheduler'
require 'openwfe/utils'
require 'openwfe/expressions/flowexpression'


module OpenWFE

  #
  # An environment is a store for variables.
  # It's an expression thus it's storable in the expression pool.
  #
  class Environment < FlowExpression
    include Rufus::Schedulable

    names :environment

    V_PAUSED = VAR_PAUSED[1..-1]

    #
    # the variables stored in this environment.
    #
    attr_accessor :variables

    def initialize

      super
      @variables = {}
    end

    def self.new_env (
      fei, parent_id, environment_id, app_context, attributes, variables=nil)

      env = self.new

      env.fei = fei
      env.parent_id = parent_id
      env.environment_id = environment_id
      env.application_context = app_context
      env.attributes = attributes
      env.variables = variables if variables

      env
    end

    #
    # Looks up for the value of a variable in this environment.
    #
    def [] (key)

      return @variables[key] \
        if @variables.has_key?(key) or is_engine_environment?

      # else look in parent environment

      return get_parent[key] \
        if @parent_id

      # finally look in engine (global) environment

      get_expression_pool.fetch_engine_environment[key]
    end

    #
    # Binds a variable in this environment.
    #
    def []= (key, value)

      @variables[key] = value
      store_itself
    end

    #
    # Removes a variable from this environment.
    #
    def delete (key)

      @variables.delete(key)
      store_itself
    end

    #
    # This method is usually called before the environment gets wiped
    # out of the expression pool.
    # It takes care of removing subprocess templates pointed at by
    # variables in this environment.
    #
    def unbind

      @variables.each do |key, value|

        if value.kind_of?(FlowExpressionId)

          get_expression_pool.remove(value)

        #elsif value.kind_of?(FlowExpression)
        #  value.cancel
        end
      end
    end

    #
    # Returns true if this environment is the engine environment
    #
    def is_engine_environment?

      (@fei == get_expression_pool.engine_environment_id)
    end

    #
    # Should never get used, only the reschedule() method is relevant
    # for the Schedulable aspect of an environment expression.
    #
    def trigger (params)

      raise "an environment should never get directly triggered"
    end

    #
    # Will reschedule any 'Schedulable' variable found in this environment
    # this method especially targets cron expressions that are stored
    # as variables and need to be rescheduled upon engine restart.
    #
    def reschedule (scheduler)

      @fei.owfe_version = OPENWFERU_VERSION \
        if @fei.wfurl == 'ee' and @fei.wfname =='ee'
          #
          # so that older versions of engine envs get accepted

      @variables.each do |key, value|

        #ldebug { "reschedule()  - item of class #{value.class}" }

        get_expression_pool.paused_instances[@fei.wfid] = true \
          if key == V_PAUSED

        next unless value.kind_of?(Rufus::Schedulable)

        linfo { "reschedule() for instance of #{value.class.name}" }

        value.application_context = @application_context
        value.reschedule(scheduler)
      end

      store_itself
    end

    #
    # Returns the top environment for the process instance (the
    # environment just before the engine environment).
    #
    def get_root_environment

      @parent_id ? get_parent.get_root_environment : self
    end

    #
    # A shortcut to get_expression_pool.fetch_engine_environment
    #
    def get_engine_environment

      get_expression_pool.fetch_engine_environment
    end

    #
    # Fetches in an array (stack) all the values for a given variable from
    # this environment up to the engine environement (parent chain).
    #
    def lookup_variable_stack (varname, stack=[])

      val = self[varname]
      stack << [ self, val ] unless val.nil?

      return stack if is_engine_environment?
      return get_parent.lookup_variable_stack(varname, stack) if @parent_id

      get_engine_environment.lookup_variable_stack(varname, stack)
    end

    #
    # Returns a brand new hash containing the variables as seen in the
    # calling environment (doesn't include variables set at the engine level).
    #
    def lookup_all_variables

      return @variables unless @parent_id

      get_parent.lookup_all_variables.merge(@variables)
    end

    #
    # Returns a deep copy of this environment.
    #
    def dup

      Environment.new_env(
        @fei.dup,
        @parent_id,
        @environment_id,
        @application_context,
        OpenWFE::fulldup(@attributes),
        OpenWFE::fulldup(self.variables))
    end
  end

end

