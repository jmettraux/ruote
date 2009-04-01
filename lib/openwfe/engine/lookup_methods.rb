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
    # :variable or :var or :v ::
    #   matches processes with a variable with that name
    # :field or :f ::
    #   matches processes with a workitem field named like this
    # :wfid_prefix ::
    #   matches processes whose wfid (process instance id) begins with the given
    #   value
    # :wfid ::
    #   matches the process instance whose wfid (process instance id) is given
    #   here
    #
    # :to_string ::
    #   turns actual values to strings before comparing to the :value / :val
    # :recursive ::
    #   looks inside of hash/array values (else only scans first level)
    #
    def lookup_processes (options)

      val = options[:value] || options[:val]

      vf = options[:vf]
      var = options[:variable] || options[:var] || options[:v] || vf
      field = options[:field] || options[:f] || vf

      opts = {
        :wfid => options[:wfid],
        :wfid_prefix => options[:wfid_prefix]
      }
      opts[:include_classes] = Environment if var and (not field)
      opts[:workitem] = true if field and (not var)

      # do look up...

      exps = get_expression_storage.find_expressions(opts)

      vv = var or (not field)
      ff = field or (not var)

      result = exps.inject([]) do |ids, exp|

        unless ids.include?(exp.fei.wfid)
          # don't check if the id is already in

          vars = exp.is_a?(Environment) ?
            exp.variables : nil
          fields = exp.respond_to?(:applied_workitem) ?
            exp.applied_workitem.fields : nil

          h, k = if vv and vars
            [ exp.fei.wfid == '0' ? nil : vars, var ]
          elsif ff and fields
            [ fields, field ]
          elsif val != nil
            [ vars || fields, nil ]
          else
            [ nil, nil ]
          end

          if val_match?(h, k, val, options) || nested_match?(h, k, val, options)
            ids << exp.fei.wfid
          end
        end

        ids
      end
    end

    protected

    def val_match? (h, k, v, options)

      #return false unless h
      return false unless (h.respond_to?(:[]) and h.respond_to?(:values))

      return val_included?(h.values, k, v, options) unless k

      return false unless h.has_key?(k)
      return true unless v

      return val_included?([ h[k] ], k, v, options)
    end

    def val_included? (values, k, v, options)

      return true if values.include?(v)

      return true \
        if v.is_a?(Regexp) and values.find { |vv| vv.is_a?(String) and v.match(vv) }
      return true \
        if options[:to_string] and values.find { |vv| vv.to_s == v }

      return true \
        if options[:recursive] and values.find { |vv| val_match?(vv, k, v, options) }

      false
    end

    def nested_match? (h, k, v, options)

      return false unless (h and k)
      return false unless k.index('.')

      val = OpenWFE.lookup_attribute(h, k)

      return false if val == nil
      return true if v == nil

      val_included?([ val ], k, v, options)
    end

  end
end

