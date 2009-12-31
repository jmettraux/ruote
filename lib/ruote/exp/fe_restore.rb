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


require 'ruote/exp/merge'


module Ruote::Exp

  #
  # Restores the fields of the current workitem. That means usually copying
  # them from a saved version in a variable or in a separate field.
  #
  #   restore :from_var => 'v'
  #
  # or
  #
  #   restore :from_f => 'customer.address.street', :to_f => 'delivery.street'
  #
  # (yes, this sets the field 'street' inside of the field 'delivery')
  #
  # == set_fields
  #
  # This expressions has a 'set_fields' alias. It can be handy (and readable)
  # to set a bunch of workitem fields in one sweep somewhere in a process :
  #
  #   Ruote.process_definition :name => 'working hard' do
  #     sequence do
  #       set_fields :val => { 'customer' => { 'name' => 'Fred', 'age' => 40 } }
  #       participant :ref => 'delivery'
  #       participant :ref => 'invoincing'
  #     end
  #   end
  #
  class RestoreExpression < FlowExpression

    include MergeMixin

    names :restore, :set_fields

    def apply

      from =
        has_attribute(*%w[ v var variable ].map { |k| "from_#{k}" }) ||
        has_attribute(*%w[ f fld field ].map { |k| "from_#{k}" }) ||
        has_attribute(*%w[ val value ])

      to =
        has_attribute(*%w[ f fld field ].map { |k| "to_#{k}" }) ||
        has_attribute('to')

      from = 'from_var' if from == 'from_v'

      afrom = attribute(from)

      fields = if from.match(/var/)
        lookup_variable(afrom)
      elsif from.match(/f/)
        Ruote.lookup(h.applied_workitem['fields'], afrom)
      else # val
        afrom
      end

      if to
        Ruote.set(h.applied_workitem['fields'], attribute(to), fields)
      else
        h.applied_workitem['fields'] = fields
      end

      # TODO : merge strategies

      reply_to_parent(h.applied_workitem)
    end

    def reply (workitem)

      # empty, never called
    end
  end
end

