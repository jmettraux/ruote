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


require 'ruote/exp/flowexpression'


module Ruote::Exp

  #
  # Prevents two process branches from executing at the same time.
  #
  #   pdef = Ruote.process_definition :name => 'test' do
  #     concurrence do
  #       reserve :mutex => 'a' do
  #         alpha
  #       end
  #       reserve 'a' do
  #         alpha
  #       end
  #     end
  #   end
  #
  # (Nice and tiny example, turns a concurrence into a sequence...)
  #
  class ReserveExpression < FlowExpression

    names :reserve

    def apply

      return reply_to_parent(@applied_workitem) if tree_children.empty?

      @mutex_name = attribute(:mutex) || attribute_text
      @mutex_name = 'reserve' if @mutex_name.strip == ''

      persist

      raise(
        ArgumentError.new("can't bind reserve mutex at engine level")
      ) if @mutex_name.match(/^\/\//)

      #mutex = lookup_variable(@mutex_name) || FlowMutex.new(@mutex_name)
      #mutex.register(self)

      get_or_set_variable(@mutex_name) do |mutex|
        mutex ||= FlowMutex.new(@mutex_name)
        mutex.register(self)
        mutex
      end
    end

    def reply (workitem)

      get_or_set_variable(@mutex_name) do |mutex|
        mutex.release(self)
        mutex
      end

      reply_to_parent(workitem)
    end

    def cancel (flavour)

      super

      get_or_set_variable(@mutex_name) do |mutex|
        mutex.release(self)
        mutex
      end
    end

    def enter

      # TODO : emit message ?

      apply_child(0, @applied_workitem)
    end
  end

  #
  # A FlowMutex, keeps track of the reserve expression waiting on a mutex to
  # unlock...
  #
  class FlowMutex

    attr_reader :name, :feis

    def initialize (name)

      @name = name
      @feis = []
    end

    def register (fexp)

      @feis << fexp.fei

      fexp.enter if @feis.size == 1
    end

    def release (fexp)

      @feis.shift

      return if @feis.empty?

      fexp.context[:s_expression_storage][@feis.first].enter
    end

    def inspect

      [ :flowmutex, @name, @feis.collect { |fei| fei.to_s } ]
    end
  end
end

