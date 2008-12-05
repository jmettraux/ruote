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
    # A method for looking up process instances. It expects some options /
    # parameters. The scope is rather wide, it may look among fields
    # (attributes) of workitems and variables of processes.
    #
    # Returns an array of wfid (workflow instance ids)
    #
    # :value or :val ::
    #   matches processes with a field or variable with the given value
    # :name ::
    #   matches processes containing a field or a variable with that name
    # :variable_name or :var_name or :v_name ::
    #   matches processes with a variable with that name
    # :field_name or :f_name ::
    #   matches processes with a workitem field named like this
    # :wfid_prefix ::
    #   matches processes whose wfid (process instance id) begins with the given
    #   value
    # :wfid ::
    #   matches the process instance whose wfid (process instance id) is given
    #   here
    #
    def lookup_processes (options)

      val = options[:value] || options[:val]

      vf = options[:vf]
      var = options[:variable] || options[:var] || options[:v] || vf
      field = options[:field] || options[:f] || vf

      raise "specify at least :variable or :field" \
        if (var == nil) and (field == nil)

      opts = {
        :wfid => options[:wfid],
        :wfid_prefix => options[:wfid_prefix]
      }

      # do look up...

      opts[:include_classes] = Environment if field == nil

      exps = get_expression_storage.find_expressions(opts)

      result = exps.find_all do |exp|
        v_match?(exp, var, val) || f_match?(exp, field, val)
      end

      result.collect { |exp| exp.fei.wfid }
    end

    protected

      def f_match? (exp, field, value)

        return false unless field
        return false unless exp.respond_to?(:applied_workitem)

        h_match?(exp.applied_workitem.attributes, field, value, true)
      end

      def v_match? (exp, var, value)

        return false unless var
        return false unless exp.is_a?(Environment)
        return false if exp.fei.wfid == '0' # (engine environment)

        h_match?(exp.variables, var, value)
      end

      def h_match? (h, k, v, recursive=false)

        val = h[k]

        if val != nil
          case v
            when nil then return true
            when Regexp then return true if v.match(val)
            else return true if v == val
          end
        end

        return false unless recursive

        h.values.each do |val|
          return true if val.is_a?(Hash) and h_match?(val, k, v, true)
        end

        false
      end
  end
end

