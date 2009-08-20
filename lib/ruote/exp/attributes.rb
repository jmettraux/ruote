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
    def lookup_value (prefix)

      if key = has_attribute(*list_att_keys(prefix, [ '', 'val', 'value' ]))

        attribute(key, @applied_workitem)

      elsif key = has_attribute(*list_att_keys(prefix, %w[ v var variable ]))

        key = attribute(key, @applied_workitem)
        lookup_variable(key)

      elsif key = has_attribute(*list_att_keys(prefix, %w[ f fld field ]))

        key = attribute(key, @applied_workitem)
        @applied_workitem.attributes[key]

      else

        nil
      end
    end

    # Returns a Hash containing all attributes set for an expression with
    # their values resolved.
    #
    def lookup_attributes

      attributes.keys.inject({}) { |h, k| h[k] = attribute(k); h }
    end

    protected

    def list_att_keys (prefix, suffixes)

      suffixes.collect { |s| s.length < 1 ? prefix : "#{prefix}_#{s}" }
    end
  end
end

