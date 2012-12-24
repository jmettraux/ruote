#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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


module Ruote::Exp

  #
  # 're-opening' the FlowExpression class to add the methods about variables.
  #
  class FlowExpression

    # A shortcut to the variables held in the expression (nil if none held).
    #
    def variables

      @h['variables']
    end

    # Returns a fresh hash of all the variables visible from this expression.
    #
    # This is used mainly when forgetting an expression.
    #
    def compile_variables

      vars = h.parent_id ? parent.compile_variables : {}
      vars.merge!(h.variables) if h.variables

      vars
    end

    # Looks up the value of a variable in expression tree
    # (seen from a leaf, it looks more like a stack than a tree)
    #
    def lookup_variable(var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      if prefix == '//'
        return @context.storage.get_engine_variable(var)
      end

      if prefix == '/' && par = parent
        return par.lookup_variable(var, prefix)
      end

      if h.variables and Ruote.has_key?(h.variables, var)
        return Ruote.lookup(h.variables, var)
      end

      if h.parent_id && h.parent_id['engine_id'] == @context.engine_id
        #
        # do not lookup variables in a remote engine ...

        (return parent.lookup_variable(var, prefix)) rescue nil
          # if the lookup fails (parent gone) then rescue and let go
      end

      @context.storage.get_engine_variable(var)
    end

    # A shortcut for #lookup_variable
    #
    alias :v :lookup_variable

    # A shortcut for #lookup_variable
    #
    alias :lv :lookup_variable

    # Sets a variable to a given value.
    # (will set at the appropriate level).
    #
    def set_variable(var, val, override=false)

      fexp, v = locate_set_var(var, override) || locate_var(var)

      fexp.un_set_variable(:set, v, val, (fexp.h.fei != h.fei)) if fexp
    end

    # Unbinds a variables.
    #
    def unset_variable(var, override=false)

      fexp, v = locate_set_var(var, override) || locate_var(var)

      fexp.un_set_variable(:unset, v, nil, (fexp.h.fei != h.fei)) if fexp
    end

    # TODO : rdoc rewrite needed
    #
    # This method is mostly used by the worker when looking up
    # a process name or participant name bound under a variable.
    #
    def iterative_var_lookup(k)

      v = lookup_variable(k)

      return [ k, v ] unless (v.is_a?(String) or v.is_a?(Symbol))

      iterative_var_lookup(v)
    end

    protected

    # Sets (or unsets) the value of a local variable
    #
    # val should be nil in case of 'unset'.
    #
    def un_set_variable(op, var, val, should_persist)

      result = if op == :set
        Ruote.set(h.variables, var, val)
      else # op == :unset
        Ruote.unset(h.variables, var)
      end

      if should_persist && r = try_persist # persist failed, have to retry

        @h = r
        un_set_variable(op, var, val, true)

      else # success (even when should_persist == false)

        @context.storage.put_msg("variable_#{op}", 'var' => var, 'fei' => h.fei)
      end

      result
    end

    VAR_PREFIX_REGEX = /^(\/{0,2})\/*(.+)$/

    # Used by lookup_variable and set_variable to extract the
    # prefix in a variable name
    #
    def split_prefix(var, prefix)

      if prefix.nil?
        m = VAR_PREFIX_REGEX.match(var.to_s)
        prefix = m[1]
        var = m[2]
      end

      [ var, prefix ]
    end

    # Returns the flow expression that owns a variable (or the one
    # that should own it) and the var without its potential / prefixes.
    #
    # In other words:
    #
    #   [ owner, varname_without_slashes ]
    #
    # When a location for the variable could not be found, it returns:
    #
    #   [ nil, nil ]
    #
    def locate_var(var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      if prefix == '//' # engine variable
        nil
      elsif prefix == '/' && par = parent # process variable
        par.locate_var(var, prefix)
      elsif h.variables # it's here
        [ self, var ]
      elsif par = parent # look in the parent expression
        par.locate_var(var, prefix)
      else # uprooted var lookup...
        [ nil, nil ]
      end
    end

    # When used with override = true(ish), will try to locate the binding site
    # for the variable and return it.
    #
    # If override is set to 'sub', will stop before digging into the parent
    # subprocess.
    #
    def locate_set_var(var, override)

      hk = h.variables && h.variables.has_key?(var)

      if ( ! override) || var.match(/^\//)
        false
      elsif override == 'sub' && DefineExpression.is_definition?(tree) && ! hk
        false
      elsif hk
        [ self, var ]
      elsif par = parent
        par.locate_set_var(var, override)
      else
        false
      end
    end

    def set_v(key, value, opts={})

      if opts[:unset]
        unset_variable(key, opts[:override])
      else
        set_variable(key, value, opts[:override])
      end
    end

    def set_f(key, value, opts={})

      if opts[:unset]
        Ruote.unset(h.applied_workitem['fields'], key)
      else
        Ruote.set(h.applied_workitem['fields'], key, value)
      end
    end

    PREFIX_REGEX = /^([^:]+):(.+)$/
    F_PREFIX_REGEX = /^f/

    def set_vf(key, value, opts={})

      field, key = if m = PREFIX_REGEX.match(key)
        [ F_PREFIX_REGEX.match(m[1]), m[2] ]
      else
        [ true, key ]
      end

      field ? set_f(key, value, opts) : set_v(key, value, opts)
    end
  end
end

