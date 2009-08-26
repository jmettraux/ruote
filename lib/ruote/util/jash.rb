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

module Ruote

  #
  # An .encode method and a .decode method.
  #
  # Attempts to encode Ruby instances into something that is easily turned
  # into a JSON string. And back.
  #
  # Raises an argument error when it can't encode/decode.
  #
  module Jash

    K = '!k'

    PASS = [ NilClass, String, Fixnum, Float, TrueClass, FalseClass ]
    NOPASS = [ Symbol ]

    # Turns the object into something that can be turned into a JSON string.
    #
    #   class Car
    #     attr_accessor :brand, :doors
    #     def initialize
    #       @brand = 'citroen'
    #     end
    #   end
    #
    #   # ...
    #
    #   Ruote::Jash.encode(Car.new))
    #     # => {"_ruote_jash_class_"=>"Car", "@brand"=>"citroen" }
    #
    def self.encode (o)

      return o \
        if PASS.include?(o.class)

      return o.collect { |e| encode(e) } \
        if o.is_a?(Array)

      return o.inject({}) { |h, (k, v)|
        raise(
          ArgumentError.new("can't encode hash with a non-string key")
        ) unless k.is_a?(String)
        h[k] = encode(v)
        h
      } if o.is_a?(Hash)

      raise(
        ArgumentError.new("can't encode object of class #{o.class}")
      ) if NOPASS.include?(o.class)

      h = { K => o.class.name }

      vs = o.respond_to?(:to_yaml_properties) ?
        o.to_yaml_properties :
        o.instance_variables.sort

      vs.inject(h) { |h, k| h[k.to_s] = encode(o.instance_variable_get(k)); h }
    end

    # Turns something that just got parsed from a JSON string into a tree
    # of Ruby instances.
    #
    #   class Car
    #     attr_accessor :brand, :doors
    #     def initialize
    #       @brand = 'citroen'
    #     end
    #   end
    #
    #   # ...
    #
    #   Ruote::Jash.decode({"_ruote_jash_class_"=>"Car", "@brand"=>"citroen" })
    #     # => #<Car:0x44bde4 @brand="citroen">
    #
    def self.decode (h)

      return h if PASS.include?(h.class)

      return h.collect { |e| decode(e) } if h.is_a?(Array)

      raise(
        ArgumentError.new("can't decode item of class #{h.class}")
      ) unless h.is_a?(Hash)

      k = h.delete(K)

      return h.inject({}) { |hh, (k, v)| hh[k] = decode(v); hh } unless k

      o = constantize(k).allocate

      h.inject(o) { |o, (k, v)| o.instance_variable_set(k, decode(v)); o }
    end

    # (simpler than the one from active_support)
    #
    def self.constantize (s)

      s.split('::').inject(Object) { |c, n| n == '' ? c : c.const_get(n) }
    end
  end
end

