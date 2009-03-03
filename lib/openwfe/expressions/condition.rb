#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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


require 'openwfe/util/treechecker'


module OpenWFE

  #
  # A ConditionMixin is a mixin for flow expressions like 'if' and 'break' for
  # example.
  # It allows for shorter notations like
  #
  #   <if test="${f:approved} == true"/>
  #
  # or
  #
  #   _loop do
  #     participant :graphical_designer
  #     participant :business_analyst
  #     _break :if => "${f:approved}"
  #   end
  #
  module ConditionMixin

    #
    # This is the method brought to expression classes including this
    # mixin. Easy evaluation of a conditon expressed in an attribute.
    #
    def eval_condition (attname, workitem, nattname=nil)

      #positive = nil
      negative = nil

      positive = do_eval_condition(attname, workitem)
      negative = do_eval_condition(nattname, workitem) if nattname

      negative = (not negative) if negative != nil

      return positive if positive != nil

      negative
    end

    #
    # Returns nil if the cited attname (without or without 'r' prefix)
    # is not present.
    #
    # Attname may be a String or a Symbol, or an Array of String or Symbol
    # instances.
    #
    # Returns the Symbol the attribute if present.
    #
    def determine_condition_attribute (attname)

      #attname = [ attname ] unless attname.is_a?(Array)
      attname = Array(attname)

      attname.each do |aname|
        aname = aname.intern if aname.is_a?(String)
        return aname if has_attribute(aname)
        return aname if has_attribute("r#{aname.to_s}")
      end

      nil
    end

    protected

      def do_eval_condition (attname, workitem)

        conditional = lookup_attribute(attname, workitem)
        rconditional = lookup_attribute("r#{attname.to_s}", workitem)

        return do_eval(rconditional, workitem) \
          if rconditional and not conditional

        return nil if conditional.nil?

        conditional = unescape(conditional)

        r = eval_set(conditional)
        return r if r != nil

        begin
          return to_boolean(do_eval(conditional, workitem))
        rescue Exception => e
          # probably needs some quoting...
          ldebug { "do_eval_condition() e : #{e}" }
        end

        conditional = do_quote(conditional)

        to_boolean(do_eval(conditional, workitem))
      end

      SET_REGEX = /(\S*?)( is)?( not)? set$/

      #
      # Evals the 'x [ is][ not] set' notation...
      #
      def eval_set (cond)

        m = SET_REGEX.match cond

        return nil unless m

        val = m[1]
        n = m[3]

        ldebug do
          "eval_set() for >#{cond}<  "+
          "m[1] is '#{val}', m[3] is '#{n}'"
        end

        val = val.strip if val
        val = (val != nil and val != '')
        n = (n and n.strip == 'not')

        n ? (not val) : val
      end

    private

      #
      # Returns true if result is the "true" String or the true
      # boolean value. Returns false else.
      #
      def to_boolean (o)

        #(o == "true" or o == true)
        o = o.strip if o.is_a?(String)
        r = ! (o == nil || o == false || o == 'false' || o == '')

        ldebug { "to_boolean() o is _#{o}_ => #{r}" }

        r
      end

      #
      # unescapes '>' and '<'
      #
      def unescape (s)

        s.to_s.gsub('&amp;', '&').gsub('&gt;', '>').gsub('&lt;', '<')
      end

      #
      # Quotes the given string so that it can easily get evaluated
      # as Ruby code (a string comparison actually).
      #
      def do_quote (string)

        op = find_operator string

        return "\"#{string}\"" unless op

        op, i = op

        s = '"'
        s << string[0..i-1].strip
        s << '" '
        s << string[i, op.length]
        s << ' "'
        s << string[i+op.length..-1].strip
        s << '"'
        s
      end

      #
      # Returns the operator and its index (position) in the string.
      # Returns nil if not operator was found in the string.
      #
      def find_operator (string)

        %w{ == != <= >= < > }.each do |op|
          i = string.index(op)
          return [ op, i ] if i
        end

        nil
      end

      #
      # Evaluates the given code (after security checks)
      #
      def do_eval (s, workitem)

        get_tree_checker.check_conditional s

        # ok, green for eval

        wi = workitem
        fe = self
          #
          # wi and fe are thus available as well
          # (as self and workitem)

        eval(s, binding())
      end
  end

end

