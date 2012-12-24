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
  # Passing a | separated list of field also works :
  #
  #   filter 'city|region|country', :type => 'string'
  #     # will make sure that at least of one those field is present
  #     # any of the three that is present must hold a string
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
  # === 'is'
  #
  # Checks if a field holds the given value.
  #
  #   filter 'x', :is => true
  #   filter 'x', :is => [ 'a', 2, 3 ]
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
  # === 'includes'
  #
  # Checks if an array includes a given value. Works with Hash values as well.
  #
  #   filter 'x', :includes => 1
  #
  # Whereas 'has' accepts multiple values, 'includes' only accepts one (like
  # Ruby's Array#include?).
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
  # For complex filters, if the first rule has :record => true, the
  # 'recording' will happen for the whole filter.
  #
  #   sequence do
  #     filter :in => [
  #       { :field => 'x', :type => 'string', :record => true },
  #       { :field => 'y', :type => 'number' } ]
  #     participant 'after'
  #   end
  #
  #
  # == transformations
  #
  # So far, only the validation aspect of filter was shown. They can also be
  # used to transform the workitem.
  #
  #   filter 'x', :type => 'string', :or => 'missing'
  #     # will replace the value of x by 'missing' if it's not a string
  #
  #   filter 'z', :remove => true
  #     # will remove the workitem field z
  #
  #   filter 'a,b,c', 'set' => '---'
  #     # sets the field a, b and c to '---'
  #
  # === 'remove'
  #
  # Removes a field (or a subfield).
  #
  #   filter 'z', :remove => true
  #
  # === 'default'
  #
  # If there is no value for a field, sets it
  #
  #   filter 'x', 'default' => 0
  #     # will set x to 0, if it's not set or its value is nil
  #
  #   filter '/^user-.+/', 'default' => 'nemo'
  #     # will set any 'user-...' field to 'nemo' if its value is nil
  #
  # === 'or'
  #
  # 'or' combines with a condition. The 'or' value is set if the condition
  # evaluates to false.
  #
  # Using 'or' without a condition makes it equivalent to a 'default'.
  #
  #   filter 'x', 'or' => 0
  #     # will set x to 0, if it's not set or its value is nil
  #
  #   filter 'x', 'type' => 'number', 'or' => 0
  #     # if x is not set or is not a number, will set it to 0
  #
  # Multiple conditions are OK
  #
  #   filter 'x', 't' => 'array', 'has' => 'cat', 'or' => []
  #     # if x is an array and has the 'cat' element, nothing will happen.
  #     # Else x will be set to [].
  #
  # === 'and'
  #
  # 'and' is much like 'or', but it triggers if the condition evaluates to true.
  #
  #   filter 'x', 'type' => number, 'and' => '*removed*'
  #     # if x is a number, it will replace it with '*removed*'
  #
  # === 'set'
  #
  # Like 'remove' removes unconditionally, 'set' sets a field unconditionally.
  #
  #   filter 'x', 'set' => 'blue'
  #     # sets the field x to 'blue'
  #
  # === copy, merge, migrate / to, from
  #
  #   # in :   { 'x' => 'y' }
  #   filter 'x', 'copy_to' => 'z'
  #   # out :  { 'x' => 'y', 'z' => 'y' }
  #
  #   # in :   { 'x' => 'y' }
  #   filter 'z', 'copy_from' => 'x'
  #   # out :  { 'x' => 'y', 'z' => 'y' }
  #
  #   # in :   { 'x' => 'y' }
  #   filter 'z', 'copy_from' => 'x'
  #   # out :  { 'x' => 'y', 'z' => 'y' }
  #
  #   # in :   { 'a' => %w[ x y ]})
  #   filter '/a\.(.+)/', 'copy_to' => 'b\1'
  #   # out :  { 'a' => %w[ x y ], 'b0' => 'x', 'b1' => 'y' },
  #
  #   # in :   { 'a' => %w[ x y ]})
  #   filter '/a!(.+)/', 'copy_to' => 'b\1'
  #   # out :  { 'a' => %w[ x y ], 'b0' => 'x', 'b1' => 'y' },
  #     #
  #     # '!' is used as a replacement for '\.' in regexes
  #
  #   # in :   { 'a' => 'b', 'c' => 'd', 'source' => [ 7 ] })
  #   filter '/^.$/', 'copy_from' => 'source.0'
  #   # out :  { 'a' => 7, 'c' => 7, 'source' => [ 7 ] },
  #
  # ...
  #
  # 'copy_to' and 'copy_from' copy whole fields. 'move_to' and 'move_from'
  # move fields.
  #
  # 'merge_to' and 'merge_from' merge hashes (or add values to
  # arrays), 'push_to' and 'push_from' are aliases for 'merge_to' and
  # 'merge_from' respectively.
  #
  # 'migrate_to' and 'migrate_from' act like 'merge_to' and 'merge_from' but
  # delete the merge source afterwards (like 'move').
  #
  # All those hash/array filter operations understand the '.' field, meaning
  # the hash being filtered itself.
  #
  #   # in :   { 'x' => { 'a' => 1, 'b' => 2 } })
  #   filter 'x', 'merge_to' => '.'
  #   # out :  { 'x' => { 'a' => 1, 'b' => 2 }, 'a' => 1, 'b' => 2 },
  #
  # === access to 'previous versions' with ~ and ~~
  #
  # Before a filter is applied, a copy of the hash to filter is placed under
  # the '~' key in the hash itself.
  #
  # this filter will at first set the field x to 0, and then reset it to its
  # original value :
  #
  #   filter :in => [
  #     { :field => 'x', :set => 0 },
  #     { :field => 'x', :copy_from => '~.x' }
  #   ]
  #
  # For the 'filter' expression, '~~' contains the same thing as '~', but
  # for the :filter attribute, it contains the hash (workitem fields) as
  # it was when the expression with the :filter attribute got reached (applied).
  #
  # === 'restore' and 'restore_from'
  #
  # Since these two filter operations leverage '~~', they're not very useful
  # for the 'filter' expression. But they make lots of sense for the :filter
  # attribute.
  #
  #   # in :   { 'x' => 'a', 'y' => 'a' },
  #   filter :in => [
  #     { 'field' => 'x', 'set' => 'X' },
  #     { 'field' => 'y', 'set' => 'Y' },
  #     { 'field' => '/^.$/', 'restore' => true } ]
  #   # out :   { 'x' => 'a', 'y' => 'a' },
  #
  #   # in :   { 'x' => 'a', 'y' => 'a' },
  #   filter :in => [
  #     { 'field' => 'A', 'set' => {} },
  #     { 'field' => '.', 'merge_to' => 'A' },
  #     { 'field' => 'x', 'set' => 'X' },
  #     { 'field' => 'y', 'set' => 'Y' },
  #     { 'field' => '/^[a-z]$/', 'restore_from' => 'A' },
  #     { 'field' => 'A', 'delete' => true } ]
  #   # out :  { 'x' => 'a', 'y' => 'a' })
  #
  # === 'take' and 'discard'
  #
  # (doesn't work well with the filter expression, it works better with
  # filter as an attribute)
  #
  # Those two only make sense in out filters. One should use one or the other in
  # a filter, but not both. It's probably better to use them at the bottom of
  # the filters (last positions), because they switch the applied workitem
  # (apply time) with the current workitem (reply time).
  #
  # 'take' means "the fields to consider are the one in the applied workitem
  # plus the ones from the new workitem listed here".
  #
  # 'discard' means "the fields to consider are the the ones of the applied
  # workitem plus all the ones from the new workitem except those listed here".
  #
  #   subprocess 'list_products', :filter => { :out => [
  #     { 'field' => 'products', 'take' => true },
  #     { 'field' => 'point_of_contact', 'take' => true }
  #   ] }
  #     # whatever the fields set by 'list_products', only 'products' and
  #     # 'point_of_contact' make it through
  #
  # Saying :discard => true means "completely ignore any workitem field set
  # by this expression".
  #
  #   subprocess 'review_document', :discard => true
  #
  #
  # == short forms
  #
  # Could help make filters a bit more compact.
  #
  # * 'size', 'sz'
  # * 'empty', 'e'
  # * 'in', 'i'
  # * 'has', 'h'
  # * 'type', 't'
  # * 'match', 'm'
  # * 'smatch', 'sm'
  # * 'valid', 'v'
  #
  # * 'remove', 'rm', 'delete', 'del'
  # * 'set', 's'
  # * 'copy_to', 'cp_to'
  # * 'move_to', 'mv_to'
  # * 'merge_to', 'mg_to'
  # * 'migrate_to', 'mi_to'
  # * 'restore', 'restore_from', 'rs'
  #
  #
  # == top-level 'or'
  #
  # Filters may be used to transform hashes or to validate them. In both cases
  # the filters seen until now were like chained by a big AND.
  #
  # It's OK to write
  #
  #   filter :in => [
  #     { 'field' => 'server_href', 'smatch' => '^https?:\/\/' },
  #     'or',
  #     { 'field' => 'nickname', 'type' => 'string' } ]
  #
  # Granted, this is mostly for validation purposes, but it also works
  # with transformations (as soon as an 'or' child succeeds it's returned
  # and the other children are not evaluated).
  #
  #
  # == compared to the :filter attribute
  #
  # The :filter attribute accepts participant names, but for this filter
  # expression, it makes no sense accepting partipants... Simply invoke
  # the participant as usual.
  #
  # The 'restore' operation makes lots of sense for the :filter attribute
  # though.
  #
  #
  # == filtering with rules in a block
  #
  # This filter
  #
  #   filter :in => [
  #     { :field => 'x', :type => 'string' },
  #     { :field => 'y', :type => 'number' }
  #   ]
  #
  # can be rewritten as
  #
  #   filter do
  #     field 'x', :type => 'string'
  #     field 'y', :type => 'number'
  #   end
  #
  # The field names can be passed directly as head of each rule :
  #
  #   filter do
  #     x :type => 'string'
  #     y :type => 'number'
  #   end
  #
  class FilterExpression < FlowExpression

    names :filter

    def apply

      h.applied_workitem['fields'].delete('__result__')
        #
        # get rid of __result__

      filter =
        referenced_filter || complete_filter || one_line_filter || block_filter

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

    # Filter is passed in a block (which is not evaluted as a ruote branch
    # but immediately translated into a filter.
    #
    #   pdef = Ruote.process_definition do
    #     filter do
    #       field 'x', :type => 'string'
    #       field 'y', :type => 'number'
    #     end
    #   end
    #
    # Note : 'or' is OK
    #
    #   pdef = Ruote.process_definition do
    #     filter do
    #       field 'x', :type => 'string'
    #       _or
    #       field 'y', :type => 'number'
    #     end
    #   end
    #
    def block_filter

      return nil if tree.last.empty?

      tree.last.collect { |line|

        next 'or' if line.first == 'or'

        rule = line[1].remap { |(k, v), h|
          if v == nil
            h['field'] = k
          else
            h[k] = v
          end
        }

        rule['field'] ||= line.first

        rule
      }
    end

    # Filter is somewhere else (process variable or workitem field)
    #
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

    # Filter is passed with an :in attribute.
    #
    #   Ruote.process_definition do
    #     filter :in => [
    #       { :field => 'x', :type => 'string' },
    #       { :field => 'y', :type => 'number' }
    #     ]
    #   end
    #
    def complete_filter

      return nil if attribute_text != ''

      attribute(:in)
    end

    # Filter thanks to the attributes of the expression.
    #
    #   pdef = Ruote.process_definition do
    #     filter 'x', :type => 'string', :record => true
    #     filter 'y', :type => 'number', :record => true
    #   end
    #
    def one_line_filter

      if (attributes.keys - COMMON_ATT_KEYS - %w[ ref original_ref ]).empty?
        return nil
      end

      [ attributes.remap { |(k, v), h|
        if v.nil?
          h['field'] = k
        else
          h[k] = v
        end
      } ]
    end
  end
end

