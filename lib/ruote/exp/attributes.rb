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
  # Those methods are mixed in FlowExpression. They were put here to offload
  # FlowExpression and especially, to gather them around their attribute topic.
  #
  module AttributesMixin

    # Given a list of attribute names, returns the first attribute name for
    # which there is a value.
    #
    def has_attribute (*args)

      args.each { |a| a = a.to_s; return a if attributes[a] != nil }

      nil
    end

    alias :has_att :has_attribute

    # Looks up the value for attribute n.
    #
    def attribute (n, workitem=@applied_workitem, options={})

      n = n.to_s

      default = options[:default]
      escape = options[:escape]
      string = options[:to_s] || options[:string]

      v = attributes[n]

      v = if v == nil
        default
      elsif escape
        v
      else
        Ruote.dosub(v, self, workitem)
      end

      v = v.to_s if v and string

      v
    end

    # Returns the value for attribute 'key', this value should be present
    # in the array list 'values'. If not, the default value is returned.
    # By default, the default value is the first element of 'values'.
    #
    def att (key, values, opts={})

      default = opts[:default] || values.first

      val = attribute(key)
      val = val.to_s if val

      #raise(
      #  ArgumentError.new("attribute '#{key}' missing in #{tree}")
      #) if opts[:mandatory] && val == nil
      #raise(
      #  ArgumentError.new("attribute '#{key}' has invalid value in #{tree}")
      #) if opts[:enforce] && (not values.include?(val))

      values.include?(val) ? val : default
    end

    # prefix = 'on' => will lookup on, on_val, on_value, on_v, on_var,
    # on_variable, on_f, on_fld, on_field...
    #
    def lookup_val_prefix (prefix, att_options={})

      lval(
        [ prefix ] + [ 'val', 'value' ].map { |s| "#{prefix}_#{s}" },
        %w[ v var variable ].map { |s| "#{prefix}_#{s}" },
        %w[ f fld field ].map { |s| "#{prefix}_#{s}" },
        att_options)
    end

    def lookup_val (att_options={})

      lval(
        VV,
        s_cartesian(%w[ v var variable ], VV),
        s_cartesian(%w[ f fld field ], VV),
        att_options)
    end

    # Returns a Hash containing all attributes set for an expression with
    # their values resolved.
    #
    def compile_atts (opts={})

      attributes.keys.inject({}) { |h, k|
        h[k] = attribute(k, @applied_workitem, opts)
        h
      }
    end

    # Like compile_atts, but the keys are expanded as well.
    #
    # Useful for things like
    #
    #   set "f:${v:field_name}" => "${v:that_variable}"
    #
    def expand_atts (opts={})

      attributes.keys.inject({}) { |h, k|
        kk = Ruote.dosub(k, self, @applied_workitem)
        h[kk] = attribute(k, @applied_workitem, opts)
        h
      }
    end

    protected

    VV = %w[ val value ]

    def s_cartesian (a0, a1)

      a0.inject([]) { |a, e0| a + a1.collect { |e1| "#{e0}_#{e1}" } }
    end

    def lval (vals, vars, flds, att_options)

      if k = has_att(*vals)

        attribute(k, @applied_workitem, att_options)

      elsif k = has_att(*vars)

        k = attribute(k, @applied_workitem, att_options)
        lookup_variable(k)

      elsif k = has_att(*flds)

        k = attribute(k, @applied_workitem, att_options)
        @applied_workitem.attributes[k]

      else

        nil
      end
    end
  end
end

