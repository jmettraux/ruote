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


module Ruote

  #
  # To get a YAML serializer :
  #
  #   serializer = Serializer.new(:yaml)
  #
  # A marshal + base64 one :
  #
  #   serializer = Serializer.new(:marshal64)
  #
  # A marshal only one :
  #
  #   serializer = Serializer.new(:marshal)
  #
  # For the rest, it's the classical :
  #
  #   data = serializer.encode(object)
  #
  #   object = serializer.decode(data)
  #
  class Serializer

    #--
    # prepare / encode / decode lambda pairs
    #++

    # plain marshal serialization
    #
    MARSHAL = [
      lambda { },
      lambda { |o| Marshal.dump(o) },
      lambda { |s| Marshal.load(s) }
    ]

    # marshal serialization with base64 encoding
    #
    MARSHAL64 = [
      lambda { require 'base64' },
      lambda { |o| Base64.encode64(Marshal.dump(o)) },
      lambda { |s| Marshal.load(Base64.decode64(s)) }
    ]

    # YAML serialization
    #
    YAML = [
      lambda { require 'yaml' },
      lambda { |o| ::YAML.dump(o) },
      lambda { |s| ::YAML.load(s) }
    ]

    #JASH = ...

    # The flavour map
    #
    FLAVOURS = {
      :marshal => MARSHAL, :marshal64 => MARSHAL64, :yaml => YAML
    }

    def initialize (flavour)

      @flavour = FLAVOURS[flavour] || MARSHAL64

      @flavour[0].call # initializes the flavour
    end

    def encode (o)

      @flavour[1].call(o)
    end

    def decode (s)

      @flavour[2].call(s)
    end
  end
end

