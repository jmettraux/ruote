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

    #
    # Turning a FilterDefinition instance into a hash
    #
    def to_h
      {
        'class' => self.class.name,
        'closed' => @closed,
        'add_ok' => @add_ok,
        'remove_ok' => @remove_ok,
        'fields' => @fields.collect { |f| f.to_h }
      }
    end

    #
    # Rebuilding a FilterDefinition from a hash
    #
    def self.from_h (h)
      fd = self.new
      fd.closed = h['closed'] || false
      fd.add_ok = h['add_ok'] || false
      fd.remove_ok = h['remove_ok'] || false
      fd.fields = (h['fields'] || []).collect { |hh| Field.from_h(hh) }
      fd
    end

    def add_allowed= (b)
      @add_ok = b
    end
    def remove_allowed= (b)
      @remove_ok = b
    end

    def may_add?
      @add_ok
    end
    def may_remove?
      @remove_ok
    end

    #
    # Adds a field to the filter definition
    #
    #   filterdef.add_field('readonly', 'r')
    #   filterdef.add_field('hidden", nil)
    #   filterdef.add_field('writable', :w)
    #   filterdef.add_field('read_write', :rw)
    #   filterdef.add_field('^toto_.*', :r)
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
    #   f0.add_field('a', 'r')
    #   f0.add_field('b', 'rw')
    #   f0.add_field('c', '')
    #
    #   m0 = {
    #     'a' => 'A',
    #     'b' => 'B',
    #     'c' => 'C',
    #     'd' => 'D',
    #   }
    #
    #   m1 = f0.filter_in m0
    #   assert_equal m1, { 'a' => 'A', 'b' => 'B' }
    #
    #   f0.closed = false
    #
    #   m2 = f0.filter_in m0
    #   assert_equal m2, { 'a' => 'A', 'b' => 'B', 'd' => 'D' }
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
      OpenWFE::fulldup(self)
    end

    protected

      #
      # pre-digesting the two maps
      #
      def build_out_map (original_map, map)

        keys = {}
        keys.merge!(original_map)
        keys.merge!(map)

        keys.keys.inject({}) { |h, k|
          h[k] = [ get_field(k), original_map[k], map[k] ]; h
        }
      end

      #
      # Returns the first field mapping a given key
      #
      def get_field (key)
        @fields.detect { |f| key.match(f.regex) }
      end

      class Field
        attr_accessor :regex, :permissions

        def to_h
          {
            'class' => self.class.name,
            'regex' => YAML.dump(@regex),
            'permissions' => @permissions
          }
        end

        def self.from_h (h)
          f = Field.new
          f.regex = YAML.load(h['regex'])
          f.permissions = h['permissions']
          f
        end

        def may_read?
          @permissions.to_s.index('r') != nil
        end

        def may_write?
          @permissions.to_s.index('w') != nil
        end

        def no_rights?
          @permissions.to_s == ''
        end
      end
  end
end
