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

    #def initialize (
    #  fei, parent, environment_id, application_context, attributes)
    #  super(fei, parent, environment_id, application_context, attributes)
    #  @variables = {}
    #end

    def initialize

      super

      @variables = {}
    end

    def self.new_env (fei, parent_id, environment_id, app_context, attributes)

      env = self.new

      env.fei = fei
      env.parent_id = parent_id
      env.environment_id = environment_id
      env.application_context = app_context
      env.attributes = attributes

      env
    end

    #
    # Looks up for the value of a variable in this environment.
    #
    def [] (key)

      value = @variables[key]

      return value \
        if @variables.has_key?(key) or is_engine_environment?

      return get_parent[key] if @parent_id

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

      @variables.delete key
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

      #ldebug { "get_root_environment\n#{self}" }

      return self unless @parent_id

      get_parent.get_root_environment
    end

    #--
    #def get_subprocess_environment
    #  return self if not @parent_id
    #  return self if @parent_id.sub_instance_id != @fei.sub_instance_id
    #  get_parent.get_subprocess_environment
    #end
    #++

    #
    # Returns a deep copy of this environment.
    #
    def dup

      env = Environment.new_env(
        @fei.dup,
        @parent_id,
        @environment_id,
        @application_context,
        OpenWFE::fulldup(@attributes))

      env.variables = OpenWFE::fulldup(self.variables)

      env
    end
  end

end

