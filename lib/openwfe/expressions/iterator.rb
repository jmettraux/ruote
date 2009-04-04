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


module OpenWFE

  #
  # Iterator instances keep track of the position of an iteration.
  # This class is meant to be used both by <iterator> and
  # <concurrent-iterator>.
  #
  class Iterator

    ITERATOR_COUNT = '__ic__'
    ITERATOR_POSITION = '__ip__'

    attr_accessor :iteration_index
    attr_accessor :iteration_list
    attr_accessor :to_field
    attr_accessor :to_variable
    attr_accessor :value_separator

    #
    # Builds a new iterator, serving a given iterator_expression.
    # The second parameter is the workitem (as applied to the iterator
    # expression).
    #
    def initialize (iterator_expression, workitem)

      @to_field = iterator_expression\
        .lookup_attribute(:to_field, workitem)
      @to_variable = iterator_expression\
        .lookup_attribute(:to_variable, workitem)

      @value_separator = iterator_expression\
        .lookup_attribute(:value_separator, workitem)

      @value_separator = /,\s*/ unless @value_separator

      @iteration_index = 0

      #raw_list = iterator_expression.lookup_vf_attribute(
      #  workitem, :value, :prefix => :on)
      #raw_list ||= iterator_expression.lookup_attribute(:on, workitem)

      raw_list =
        iterator_expression.lookup_vf_attribute(
          workitem, :value, :prefix => :on) ||
        iterator_expression.lookup_vf_attribute(
          workitem, nil, :prefix => :on)

      @iteration_list = extract_iteration_list raw_list

      workitem.attributes[ITERATOR_COUNT] = @iteration_list.length
    end

    #
    # Has the iteration a next element ?
    #
    def has_next?

      @iteration_index < @iteration_list.size
    end

    #
    # Returns the size of this iterator, or rather, the size of the
    # underlying iteration list.
    #
    def size

      @iteration_list.size
    end

    #
    # Prepares the iterator expression and the workitem for the next
    # iteration.
    #
    def next (workitem)

      position_at(workitem, @iteration_index)
    end

    #
    # Positions the iterator back at position 0.
    #
    def rewind (workitem)

      position_at(workitem, 0)
    end

    #
    # Jumps to a given position in the iterator
    #
    def jump (workitem, index)

      index = if index < 0
        0
      elsif index >= @iteration_list.size
        @iteration_list.size
      else
        index
      end

      position_at(workitem, index)
    end

    #
    # Jumps a certain number of positions in the iterator.
    #
    def skip (workitem, offset)

      jump(workitem, @iteration_index + offset)
    end

    #
    # The current index (whereas @iteration_index already points to
    # the next element).
    #
    def index

      @iteration_index - 1
    end

    protected

    #
    # Positions the iterator absolutely.
    #
    def position_at (workitem, position)

      result = {}

      value = @iteration_list[position]

      return nil if (value == nil)

      if @to_field
        workitem.attributes[@to_field] = value
      else
        result[@to_variable] = value
      end

      workitem.attributes[ITERATOR_POSITION] = position
      result[ITERATOR_POSITION] = position

      @iteration_index = position + 1

      result
    end

    #
    # Extracts the iteration list from any value.
    #
    def extract_iteration_list (raw_list)

      if is_suitable_list?(raw_list)
        raw_list
      else
        extract_list_from_string raw_list.to_s
      end
    end

    #
    # Returns true if the given instance can be directly
    # used as a list.
    #
    def is_suitable_list? (instance)

      (not instance.is_a?(String)) and \
      instance.respond_to? :[] and \
      instance.respond_to? :length
    end

    #
    # Extracts the list from the string (comma separated list
    # usually).
    #
    def extract_list_from_string (s)

      s.split @value_separator
    end
  end

end

