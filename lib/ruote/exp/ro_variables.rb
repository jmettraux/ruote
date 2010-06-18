#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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
    def lookup_variable (var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return @context.storage.get_engine_variable(var) \
        if prefix.length >= 2

      return parent.lookup_variable(var, prefix) \
        if h.parent_id && prefix.length >= 1

      if h.variables

        val = Ruote.lookup(h.variables, var)

        return val if val != nil
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
    def set_variable (var, val)

      fexp, v = locate_var(var)

      raise(
        ArgumentError.new("cannot set var at engine level : #{var}")
      ) if fexp.nil?

      fexp.un_set_variable(:set, v, val, true)
    end

    # Unbinds a variables.
    #
    def unset_variable (var)

      fexp, v = locate_var(var)

      raise(
        ArgumentError.new("cannot set var at engine level : #{var}")
      ) if fexp.nil?

      should_persist = (fexp.h.fei != h.fei)
        # don't use a ticket when expression wants to modify its own vars

      fexp.un_set_variable(:unset, v, nil, should_persist)
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

    # Sets (or unsets) the value of a local variable
    #
    # val should be nil in case of 'unset'.
    #
    def un_set_variable (op, var, val, should_persist)

      if op == :set
        Ruote.set(h.variables, var, val)
      else # op == :unset
        Ruote.unset(h.variables, var)
      end

      return unless should_persist

      if r = try_persist # persist failed, have to retry

        @h = r
        un_set_variable(op, var, val, true)

      else # success

        @context.storage.put_msg("variable_#{op}", 'var' => var, 'fei' => h.fei)
      end
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

    # Returns the flow expression that owns a variable (or the one
    # that should own it) and the var without its potential / prefixes.
    #
    def locate_var (var, prefix=nil)

      var, prefix = split_prefix(var, prefix)

      return nil if prefix.length >= 2 # engine variable
      return parent.locate_var(var, prefix) if prefix.length == 1 && h.parent_id

      # no prefix...

      return [ self, var ] if h.variables
      return parent.locate_var(var, prefix) if h.parent_id

      raise "uprooted var lookup, something went wrong"
    end
  end
end

