#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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

require 'ruote/util/filter'


module Ruote::Exp

  #
  # Filter is a one-way filter expression. It filters workitem fields.
  # Validations and Transformations are possible.
  #
  # Validations will raise errors (that'll block the process segment
  # unless an :on_error attribute somehow deals with the problem).
  #
  # Transformations will copy values around fields.
  #
  # There are two ways to use it. With a single rule or with an array of
  # rules.
  #
  #   filter 'x', :type => 'string'
  #     # will raise an error if the field 'x' doesn't contain a String
  #
  # or
  #
  #   filter :in => [
  #     { :field => 'x', :type => 'string' },
  #     { :field => 'y', :type => 'number' }
  #   ]
  #
  # For the remainder of this piece of documentation, the one rule filter
  # will be used.
  #
  # == filtering targets (field names)
  #
  # Top level field names are OK :
  #
  #   filter 'customer_id', :type => 'string'
  #   filter 'invoice_id', :type => 'number'
  #
  # Pointing to fields lying deeper is OK :
  #
  #   filter 'customer.id', :type => 'number'
  #   filter 'customer.name', :type => 'string'
  #   filter 'invoice', :type => 'array'
  #   filter 'invoice.0.id', :type => 'number'
  #
  # (Note the dollar notation is also OK with such dotted identifiers)
  #
  # It's possible to target multiple fields by passing a list of field names
  # or a regular expression.
  #
  #   filter 'city, region, country', :type => 'string'
  #     # will make sure that those 3 fields hold a string value
  #
  #   filter '/^address\.x_/', :type => number
  #   filter '/^address!x_/', :type => number
  #     # fields whosename start with x_ in the address hash should be numbers
  #
  # Note the "!" used as a shortcut for "\." in the second line.
  #
  #
  # == validations
  #
  # === 'type'
  #
  # Ruote is a Ruby library, it adopts Ruby "laissez-faire" for workitem
  # fields, but sometimes, some type oriented validation is necessary.
  # Ruote limits itself to the types found in the JSON specification with
  # one or two additions.
  #
  #   filter 'x', :type => 'string'
  #   filter 'x', :type => 'number'
  #   filter 'x', :type => 'bool'
  #   filter 'x', :type => 'boolean'
  #   filter 'x', :type => 'null'
  #
  #   filter 'x', :type => 'array'
  #
  #   filter 'x', :type => 'object'
  #   filter 'x', :type => 'hash'
  #     # 'object' and 'hash' are equivalent
  #
  # It's OK to pass multiple types for a field
  #
  #   filter 'x', :type => 'bool,number'
  #   filter 'x', :type => [ 'string', 'array' ]
  #
  #   filter 'x', :type => 'string,null'
  #     # a string or null or not set
  #
  # The array and the object/hash types accept a subtype for their values
  # (a hash/object must have string keys anyway).
  #
  #   filter 'x', :type => 'array<number>'
  #   filter 'x', :type => 'array<string>'
  #   filter 'x', :type => 'array<array<string>>'
  #
  #   filter 'x', :type => 'array<string,number>'
  #     # an array of strings or numbers (both)
  #   filter 'x', :type => 'array<string>,array<number>'
  #     # an array of strings or an array of numbers
  #
  # === 'match' and 'smatch'
  #
  # 'match' will check if a field, when turned into a string, matches
  # a given regular expression.
  #
  #   filter 'x', :match => '1'
  #     # will match "11", 1, 1.0, "212"
  #
  # 'smatch' works the same but only accepts fields that are strings.
  #
  #   filter 'x', :smatch => '^user_'
  #     # valid only if x's value is a string that starts with "user_"
  #
  # === 'size' and 'empty'
  #
  # 'size' is valid for values that respond to the #size method (strings
  # hashes and arrays).
  #
  #   filter 'x', :size => 4
  #     # will be valid of values like [ 1, 2, 3, 4 ], "toto" or
  #     # { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 }
  #
  #   filter 'x', :size => [ 4, 5 ]
  #   filter 'x', :size => '4,5'
  #     # four to five elements
  #
  #   filter 'x', :size => [ 4 ]
  #   filter 'x', :size => [ 4, nil ]
  #   filter 'x', :size => '4,'
  #     # four or more elements
  #
  #   filter 'x', :size => [ nil, 4 ]
  #   filter 'x', :size => ',4'
  #     # four elements or less
  #
  # Similarly, the 'empty' check will evaluate to true (ie not raise an
  # exception) if the value responds to #empty? and is, well, not empty.
  #
  #   filter 'x', :empty => true
  #
  # === 'in'
  #
  # Checks if a value is in a given set of values.
  #
  #   filter 'x', :in => [ 1, 2, 3 ]
  #   filter 'x', :in => "john, jeff, jim"
  #
  # === 'has'
  #
  # Checks if an array contains certain values
  #
  #   filter 'x', :has => 1
  #   filter 'x', :has => "x"
  #   filter 'x', :has => [ 1, 7, 12 ]
  #   filter 'x', :has => "abraham, bob, charly"
  #
  # Also checks if a hash has certain keys (strings only of course)
  #
  #   filter 'x', :has => "x"
  #   filter 'x', :has => "abraham, bob, charly"
  #
  # === 'valid'
  #
  # Sometimes, it's better to immediately say 'true' or 'false'.
  #
  #   filter 'x', :valid => 'true'
  #   filter 'x', :valid => 'false'
  #
  # Not very useful...
  #
  # In fact, it's meant to be used with the dollar notation
  #
  #   filter 'x', :valid => '${other.field}'
  #     # will be valid if ${other.field} evaluates to 'true'...
  #
  # === cumulating validations
  #
  # As seen before, type validations can be cumulated.
  #
  #   filter 'x', :type => 'bool,number'
  #
  # Validations can be cumulated as well
  #
  #   filter 'x', :type => 'array<number>', :has => [ 1, 2 ]
  #     # will be valid if the field 'x' holds an array of numbers
  #     # and that array has 1 and 2 among its elements
  #
  # === validation errors
  #
  # By defaults a validation error will result in a process error (ie the
  # process instance will have to be manually fixed and resumed, or there
  # is a :on_error somewhere dealing automatically with errors).
  #
  # It's possible to prevent raising an error and simply record the validation
  # errors.
  #
  #   filter 'x', :type => 'bool,number', :record => true
  #
  # will enumerate validation errors in the '__validation_errors__' workitem
  # field.
  #
  #   filter 'y', :type => 'bool,number', :record => 'verrors'
  #
  # will enumerate validation errors in teh 'verrors' workitem field.
  #
  # To flush the recording field, use :flush => true
  #
  #   sequence do
  #     filter 'x', :type => 'string', :record => true
  #     filter 'y', :type => 'number', :record => true, :flush => true
  #     participant 'after'
  #   end
  #
  # the participant 'after' will only see the result of the second filter.
  #
  #
  # == transformations
  #
  # TODO
  #
  # === access to 'previous versions' with ~ and ~~
  #
  # TODO
  #
  #
  # == short forms
  #
  # TODO
  #
  class FilterExpression < FlowExpression

    names :filter

    def apply

      filter = referenced_filter || complete_filter || one_line_filter

      record = filter.first.delete('record') rescue nil
      flush = filter.first.delete('flush') rescue nil

      record = '__validation_errors__' if record == true

      opts = {
        :double_tilde => parent_id ?
          (parent.h.applied_workitem['fields'] rescue nil) : nil,
        :no_raise => record
      }
        #
        # parent_fields are placed in the ^^ available to the filter

      fields = Ruote.filter(filter, h.applied_workitem['fields'], opts)

      if record and fields.is_a?(Array)
        #
        # validation failed, :record requested, list deviations in
        # the given field name

        (flush ?
          h.applied_workitem['fields'][record] = [] :
          h.applied_workitem['fields'][record] ||= []
        ).concat(fields)

        reply_to_parent(h.applied_workitem)

      else
        #
        # filtering successful

        reply_to_parent(h.applied_workitem.merge('fields' => fields))
      end
    end

    def reply(workitem)

      # never called
    end

    protected

    def referenced_filter

      prefix, key = attribute_text.split(':')

      return nil unless %w[ v var variable f field ].include?(prefix)

      filter = prefix.match(/^v/) ?
        lookup_variable(key) : Ruote.lookup(h.applied_workitem['fields'], key)

      if filter.is_a?(Hash) and i = filter['in']
        return i
      end

      filter
    end

    def complete_filter

      return nil if attribute_text != ''

      attribute(:in)
    end

    def one_line_filter

      [ attributes.inject({}) { |h, (k, v)|
        if v.nil?
          h['field'] = k
        else
          h[k] = v
        end
        h
      } ]
    end
  end
end

