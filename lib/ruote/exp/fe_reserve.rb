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

      return reply_to_parent(h.applied_workitem) if tree_children.empty?

      h.mutex_name = attribute(:mutex) || attribute_text
      h.mutex_name = 'reserve' if h.mutex_name.strip == ''

      raise(
        ArgumentError.new("can't bind reserve mutex at engine level")
      ) if h.mutex_name.match(/^\/\//)

      set_mutex
    end

    def reply(workitem)

      release_mutex

      reply_to_parent(workitem)
    end

    def cancel(flavour)

      super

      release_mutex
    end

    def enter

      apply_child(0, h.applied_workitem)
    end

    protected

    def set_mutex

      target, var = locate_var(h.mutex_name)

      val = target.variables[var]

      # [ 'mutex', name, [ fei0, fei1, ... ] ]

      mutex = val ? val : [ 'mutex', var, [] ]

      mutex.last << h.fei

      target.variables[var] = mutex

      r = target.try_persist

      return set_mutex if r != nil

      if mutex.last.first == h.fei
        enter
      else
        persist_or_raise
      end
    end

    def release_mutex

      target, var = locate_var(h.mutex_name)

      mutex = target.variables[var]

      mutex.last.shift

      r = target.try_persist

      return release_mutex if r != nil

      next_fei = mutex.last.first

      Ruote::Exp::FlowExpression.fetch(@context, next_fei).enter if next_fei
    end
  end
end

