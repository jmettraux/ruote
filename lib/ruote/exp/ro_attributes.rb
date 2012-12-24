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
  # Those methods are added in FlowExpression. They were put here to offload
  # FlowExpression and especially, to gather them around their attribute topic.
  #
  class FlowExpression

    # Given a list of attribute names, returns the first attribute name for
    # which there is a value.
    #
    def has_attribute(*args)

      args.each { |a| a = a.to_s; return a if attributes[a] != nil }

      nil
    end

    alias :has_att :has_attribute

    # Looks up the value for attribute n.
    #
    def attribute(n, workitem=h.applied_workitem, options={})

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
        dsub(v, workitem)
      end

      v = v.to_s if v and string

      v
    end

    # Returns the value for attribute 'key', this value should be present
    # in the array list 'values'. If not, the default value is returned.
    # By default, the default value is the first element of 'values'.
    #
    def att(keys, values, opts={})

      default = opts[:default] || values.first

      val = Array(keys).collect { |key| attribute(key) }.compact.first.to_s

      values.include?(val) ? val : default
    end

    # prefix = 'on' => will lookup on, on_val, on_value, on_v, on_var,
    # on_variable, on_f, on_fld, on_field...
    #
    def lookup_val_prefix(prefix, att_options={})

      lval(
        [ prefix ] + [ 'val', 'value' ].map { |s| "#{prefix}_#{s}" },
        %w[ v var variable ].map { |s| "#{prefix}_#{s}" },
        %w[ f fld field ].map { |s| "#{prefix}_#{s}" },
        att_options)
    end

    def lookup_val(att_options={})

      lval(
        VV,
        s_cartesian(%w[ v var variable ], VV),
        s_cartesian(%w[ f fld field ], VV),
        att_options)
    end

    # Returns a Hash containing all attributes set for an expression with
    # their values resolved.
    #
    def compile_atts(opts={})

      attributes.keys.each_with_object({}) { |k, r|
        r[dsub(k)] = attribute(k, h.applied_workitem, opts)
      }
    end

    # Given something like
    #
    #   sequence do
    #     participant 'alpha'
    #   end
    #
    # in the context of the participant expression
    #
    #   attribute_text()
    #
    # will yield 'alpha'.
    #
    # Note : an empty text returns '', not the nil value.
    #
    def attribute_text(workitem=h.applied_workitem)

      text = attributes.keys.find { |k| attributes[k] == nil }

      dsub(text.to_s, workitem)
    end

    # Equivalent to #attribute_text, but will return nil if there
    # is no attribute whose values is nil.
    #
    def att_text(workitem=h.applied_workitem)

      text = attributes.keys.find { |k| attributes[k] == nil }

      text ? dsub(text.to_s, workitem) : nil
    end

    protected

    # dollar substitution for expressions.
    #
    def dsub(o, wi=h.applied_workitem)

      case o
        when String; @context.dollar_sub.s(o, self, wi)
        when Array; o.collect { |e| dsub(e, wi) }
        when Hash; o.remap { |(k, v), h| h[dsub(k, wi)] = dsub(v, wi) }
        else o
      end
    end

    # 'tos' meaning 'many "to"'
    #
    def determine_tos

      to_v = attribute(:to_v) || attribute(:to_var) || attribute(:to_variable)
      to_f = attribute(:to_f) || attribute(:to_fld) || attribute(:to_field)

      if to = attribute(:to)
        pre, key = to.split(':')
        pre, key = [ 'f', pre ] if key == nil
        if pre.match(/^f/)
          to_f = key
        else
          to_v = key
        end
      end

      [ to_v, to_f ]
    end

    # Val and Value (Sense and Sensibility ?)
    #
    VV = %w[ val value ]

    def s_cartesian(a0, a1)

      a0.inject([]) { |a, e0| a + a1.collect { |e1| "#{e0}_#{e1}" } }
    end

    def lval(vals, vars, flds, att_options)

      if k = has_att(*vals)

        attribute(k, h.applied_workitem, att_options)

      elsif k = has_att(*vars)

        k = attribute(k, h.applied_workitem, att_options)
        lookup_variable(k)

      elsif k = has_att(*flds)

        k = attribute(k, h.applied_workitem, att_options)
        Ruote.lookup(h.applied_workitem['fields'], k)

      else

        nil
      end
    end
  end
end

