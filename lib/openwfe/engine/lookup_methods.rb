#
#--
# Copyright (c) 2006-2008, John Mettraux OpenWFE.org
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


module OpenWFE

  #
  # Engine methods for looking up variables and fields (workitem attributes)
  #
  module LookupMethods

    #
    # Looks up a process variable in a process.
    # If fei_or_wfid is not given, will simply look in the
    # 'engine environment' (where the top level variables '//' do reside).
    #
    def lookup_variable (var_name, fei_or_wfid=nil)

      return get_expression_pool.fetch_engine_environment[var_name] \
        unless fei_or_wfid

      fetch_exp(fei_or_wfid).lookup_variable(var_name)
    end

    #
    # Returns the variables set for a process or an expression.
    #
    # If a process (wfid) is given, variables of the process environment
    # will be returned, else variables in the environment valid for the
    # expression (fei) will be returned.
    #
    # If nothing (or nil) is given, the variables set in the engine
    # environment will be returned.
    #
    def get_variables (fei_or_wfid=nil)

      return get_expression_pool.fetch_engine_environment.variables \
        unless fei_or_wfid

      fetch_exp(fei_or_wfid).get_environment.variables
    end

    #
    # Returns an array of wfid (workflow instance ids) whose root
    # environment contains the given variable
    #
    # If there are no matches, an empty array will be returned.
    #
    # Regular expressions are accepted as values.
    #
    # If no value is given, all processes with the given variable name
    # set will be returned.
    #
    def lookup_processes (var_name, value=nil)

      regexp = value.is_a?(Regexp) ? value : nil

      envs = get_expression_storage.find_expressions(
        :include_classes => Environment)

      envs = envs.find_all do |env|

        val = env.variables[var_name]

        #(val and ((not regexp) or (regexp.match(val))))
        if val != nil
          if regexp
            regexp.match(val)
          elsif value
            val == value
          else
            true
          end
        else
          false
        end
      end

      envs.collect { |env| env.fei.wfid }

      #envs.inject([]) do |r, env|
      #  val = env.variables[var_name]
      #  r << env.fei.wfid \
      #    if (val and ((not regexp) or (regexp.match(val))))
      #  r
      #end
        # seems slower...
    end
  end

end

