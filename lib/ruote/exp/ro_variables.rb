#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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

    # Returns a fresh hash of all the variables visible from this expression.
    #
    # This is used mainly when forgetting an expression.
    #
    def compile_variables

      vars = @parent_id ? parent.compile_variables : {}
      vars.merge!(@variables) if @variables

      vars.dup
    end

    # Looks up the value of a variable in expression tree
    # (seen from a leave, it looks more like a stack than a tree)
    #
    def lookup_variable (var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return engine.variables[var] \
        if prefix.length >= 2

      return parent.lookup_variable(var, prefix) \
        if @parent_id && prefix.length >= 1

      #if var == (attribute('name') || attribute_text)
      #  # allowing main process recursion (with the up-to-date tree)
      #  return [ @fei.expid, tree ]
      #end

      if @variables

        val = @variables[var]
        return val if val != nil
      end

      if @parent_id

        return parent.lookup_variable(var, prefix)
      end

      engine.variables[var]
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
    def set_variable (var, val, prefix=nil)

      #p [ :sv, var, @fei.to_s, val, prefix, @variables ]

      var, prefix = split_prefix(var, prefix)

      return parent.set_variable(var, val, prefix) \
        if @parent_id && prefix.length > 0

      if @variables

        with_ticket(:local_set_variable, var, val)

      elsif @parent_id

        parent.set_variable(var, val, prefix)

      #else # should not happen
      end
    end

    # Unbinds a variables.
    #
    def unset_variable (var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return parent.unset_variable(var, prefix) \
        if @parent_id && prefix.length > 0

      if @variables

        @variables.delete(var)
        persist

        wqueue.emit(:variables, :unset, :var => var, :fei => @fei)

      elsif @parent_id

        parent.unset_variable(var, prefix)

      #else # should not happen
      end
    end

    # This method is mostly used by the expression pool when looking up
    # a process name or participant name bound under a variable.
    #
    def iterative_var_lookup (k)

      v = lookup_variable(k)

      return [ k, v ] unless (v.is_a?(String) or v.is_a?(Symbol))

      iterative_var_lookup(v)
    end

    protected

    VAR_PREFIX_REGEX = /^(\/*)/

    # Used by lookup_variable and set_variable to extract the
    # prefix in a variable name
    #
    def split_prefix (var, prefix)

      if prefix.nil?
        var = var.to_s
        m = VAR_PREFIX_REGEX.match(var)
        prefix = m ? m[1][0, 2] : ''
        var = var[prefix.length..-1]
      end

      [ var, prefix ]
    end

    # Returns the flow expression that owns a variable (or the one
    # that should own it).
    #
    def lookup_var_site (var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return nil \
        if prefix.length >= 2 # engine variable

      return parent.lookup_var_site(var, prefix) \
        if prefix.length >= 1 && @parent_id

      # no prefix...

      return self \
        if @variables

      return parent.lookup_var_site(var, prefix) \
        if @parent_id

      raise "uprooted var lookup, something went wrong"
    end
  end
end

