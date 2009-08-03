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

require 'ruote/util/misc'
require 'ruote/util/lookup'


module Ruote

  class Workitem

    attr_accessor :fei
    attr_accessor :fields
    attr_accessor :participant_name

    alias :attributes :fields
    alias :attributes= :fields=

    def initialize (fields={})

      @fei = nil
      @fields = fields
    end

    # For a simple key
    #
    #   workitem.lookup('toto')
    #
    # is equivalent to
    #
    #   workitem.fields['toto']
    #
    # but for a complex key
    #
    #   workitem.lookup('toto.address')
    #
    # is equivalent to
    #
    #   workitem.fields['toto']['address']
    #
    def lookup (key, container_lookup=false)

      Ruote.lookup(@fields, key, container_lookup)
    end

    # A shortcut to the value in the field named __result__
    #
    # This field is used by the if expression for instance to determine
    # if it should branch to its 'then' or its 'else'.
    #
    def result

      @fields['__result__']
    end

    # Sets the value of the 'special' field __result__
    #
    # See #result
    #
    def result= (r)

      @fields['__result__'] = r
    end

    # Returns a deep copy of this workitem instance.
    #
    def dup

      Ruote.fulldup(self)
    end

    def to_h

      h = {}
      h['fei'] = @fei.to_h
      h['participant_name'] = @participant_name
      h['fields'] = @fields

      h
    end

    def self.from_h (h)

      wi = Workitem.new(h['fields'])
      wi.fei = FlowExpressionId.from_h(h['fei'])
      wi.participant_name = h['participant_name']

      wi
    end
  end
end

