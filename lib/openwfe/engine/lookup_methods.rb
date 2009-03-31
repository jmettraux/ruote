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

