#
#--
# Copyright (c) 2007, John Mettraux OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#
# $Id: definitions.rb 2725 2006-06-02 13:26:32Z jmettraux $
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'openwfe/utils'


module OpenWFE

  #
  # A 'filter' is used to restrict what a participant / user / segment
  # of a process may see of a workitem (filter_in) and also enforces
  # restrictions on modifications (filter_out).
  #
  class FilterDefinition

    attr_accessor \
      :closed,
      :add_ok,
      :remove_ok,
      :fields

    def initialize
      @closed = false
      @add_ok = true
      @remove_ok = true
      @fields = []
    end

    def add_allowed= (b)
      @add_ok = b
    end
    def remove_allowed= (b)
      @remove_ok = b
    end

    def may_add?
      return @add_ok
    end
    def may_remove?
      return @remove_ok
    end

    #
    # Adds a field to the filter definition
    #
    #   filterdef.add_field("readonly", "r")
    #   filterdef.add_field("hidden", nil)
    #   filterdef.add_field("writable", :w)
    #   filterdef.add_field("read_write", :rw)
    #   filterdef.add_field("^toto_.*", :r)
    #
    def add_field (regex, permissions)
      f = Field.new
      f.regex = regex
      f.permissions = permissions
      @fields << f
    end

    #
    # Takes a hash as input and returns a hash. The result will
    # contain only the readable fields.
    #
    # Consider the following test cases to see this
    # 'constraining' in action :
    #
    #   f0 = OpenWFE::FilterDefinition.new
    #   f0.closed = true
    #   f0.add_field("a", "r")
    #   f0.add_field("b", "rw")
    #   f0.add_field("c", "")
    #
    #   m0 = {
    #     "a" => "A",
    #     "b" => "B",
    #     "c" => "C",
    #     "d" => "D",
    #   }
    #
    #   m1 = f0.filter_in m0
    #   assert_equal m1, { "a" => "A", "b" => "B" }
    #
    #   f0.closed = false
    #
    #   m2 = f0.filter_in m0
    #   assert_equal m2, { "a" => "A", "b" => "B", "d" => "D" }
    #
    def filter_in (map)

      result = {}

      map.each do |key, value|

        field = get_field key

        if @closed
          result[key] = value if field and field.may_read?
        else
          result[key] = value if (not field) or field.may_read?
        end
      end

      result
    end

    def filter_out (original_map, map)

      # method with a high cyclomatic score :)

      result = {}

      build_out_map(original_map, map).each do |key, v|

        field, ovalue, nvalue = v

        #
        # adding a brand new field...

        isnew = ((not field) and (ovalue == nil) and (nvalue != nil))

        if isnew
          result[key] = nvalue if @add_ok
          next
        end

        #
        # removing a field

        isremoval = ((ovalue != nil) and (nvalue == nil))

        if isremoval
          result[key] = ovalue unless @remove_ok
          next
        end

        #
        # no modification

        haschanged = (ovalue != nvalue)

        #puts "haschanged ? #{haschanged}"

        if haschanged

          result[key] = unless field
            if @closed
              ovalue
            else
              nvalue
            end
          else
            if field.may_write?
              nvalue
            else
              ovalue
            end
          end

          next
        end

        # else, just use, the old value

        result[key] = ovalue
      end

      result
    end

    #
    # Returns a deep copy of this filter instance.
    #
    def dup
      OpenWFE::fulldup self
    end

    protected

      #
      # pre-digesting the two maps
      #
      def build_out_map (original_map, map)

        keys = {}
        keys.merge! original_map
        keys.merge! map

        m = {}
        keys.keys.each do |k|
          m[k] = [ get_field(k), original_map[k], map[k] ]
        end

        #require 'pp'; pp m
        m
      end

      #
      # Returns the first field mapping a given key
      #
      def get_field (key)
        @fields.detect do |f|
          key.match f.regex
        end
      end

      class Field
        attr_accessor :regex, :permissions

        def may_read?
          @permissions.to_s.index("r") != nil
        end

        def may_write?
          @permissions.to_s.index("w") != nil
        end

        def no_rights?
          @permissions.to_s == ""
        end
      end
  end
end
