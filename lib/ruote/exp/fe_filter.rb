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
  # == validations
  #
  # TODO
  #
  # === validation errors
  #
  # TODO
  #
  # == transformations
  #
  # TODO
  #
  class FilterExpression < FlowExpression

    names :filter

    def apply

      filter = referenced_filter || complete_filter || one_line_filter

      fields = Ruote.filter(filter, h.applied_workitem['fields'])

      reply_to_parent(h.applied_workitem.merge('fields' => fields))
    end

    def reply (workitem)

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

