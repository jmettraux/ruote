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

      vars = parent_id ? parent.compile_variables : {}
      vars.merge!(variables) if variables

      vars.dup
    end

    # Looks up the value of a variable in expression tree
    # (seen from a leave, it looks more like a stack than a tree)
    #
    def lookup_variable (var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return @context.engine.variables[var] \
        if prefix.length >= 2

      return parent.lookup_variable(var, prefix) \
        if parent_id && prefix.length >= 1

      #if var == (attribute('name') || attribute_text)
      #  # allowing main process recursion (with the up-to-date tree)
      #  return [ @fei.expid, tree ]
      #end

      if variables

        val = variables[var]
        return val if val != nil
      end

      if parent_id

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
    def set_variable (var, val)

      fexp, v = locate_var(var)

      raise(
        ArgumentError.new("cannot set var at engine level : #{var}")
      ) if fexp.nil?

      #fexp.with_ticket(:un_set_variable, :set, v, val)
      fexp.un_set_variable(:set, v, val)
    end

    # Unbinds a variables.
    #
    def unset_variable (var)

      fexp, v = locate_var(var)

      raise(
        ArgumentError.new("cannot set var at engine level : #{var}")
      ) if fexp.nil?

      #if (fexp.raw_fei == @h['fei'])
      #  #
      #  # don't use a ticket when expression wants to modify its own vars
      #  #
      #  fexp.un_set_variable(:unset, v)
      #else
      #  fexp.with_ticket(:un_set_variable, :unset, v)
      #end
      fexp.un_set_variable(:unset, v)
    end

    # This method is mostly used by the expression pool when looking up
    # a process name or participant name bound under a variable.
    #
    def iterative_var_lookup (k)

      v = lookup_variable(k)

      return [ k, v ] unless (v.is_a?(String) or v.is_a?(Symbol))

      iterative_var_lookup(v)
    end

    # This method is currently only used by the "reserve" expression. It ensures
    # that its block is passed the current value for the var (nil if not yet
    # set) and that the block is executed while a ticket for the expression
    # holding the var is held. The block is meant to return the new value
    # for the variable.
    #
    def get_or_set_variable (var, &block)

      fexp, v = locate_var(var)

      fexp.gos_variable(v, block)
        # note that block is passed as regular argument
    end

    protected

    # Sets (or unsets) the value of a local variable
    #
    def un_set_variable (op, var, val=nil)

      if op == :set
        h.variables[var] = val
      else # op == :unset
        h.variables.delete(var)
      end

      persist

      #wqueue.emit(:variables, op, :var => var, :fei => @fei)
    end

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

    # Does the magic for #get_or_set_variable (and is wrapped in a ticket).
    #
    def gos_variable (var, block)

      un_set_variable(:set, var, block.call(@variables[var]))
    end
    #with_ticket :gos_variable

    # Returns the flow expression that owns a variable (or the one
    # that should own it) and the var without its potential / prefixes.
    #
    def locate_var (var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return nil \
        if prefix.length >= 2 # engine variable

      return parent.locate_var(var, prefix) \
        if prefix.length == 1 && parent_id

      # no prefix...

      return [ self, var ] \
        if h.variables

      return parent.locate_var(var, prefix) \
        if parent_id

      raise "uprooted var lookup, something went wrong"
    end
  end
end

