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
  # The 'reserve' expression ensures that its nested child expression
  # executes while a reserved mutex is set.
  #
  # Thus
  #
  #   concurrence do
  #     reserve :mutex => :m0 do
  #       sequence do
  #         participant :alpha
  #         participant :bravo
  #       end
  #     end
  #     reserve :mutex => :m0 do
  #       participant :charly
  #     end
  #     participant :delta
  #   end
  #
  # The sequence will not but run while the participant charly is active
  # and vice versa. The participant delta is not concerned.
  #
  # The mutex is a regular variable name, thus a mutex named "//toto" could
  # be used to prevent segments of totally different process instances from
  # running.
  #
  class ReserveExpression < FlowExpression

    names :reserve

    #
    # The name of the mutex this expressions uses.
    # It's a variable name, that means it can be prefixed with
    # {nothing} (local scope), '/' (process scope) and '//' (engine /
    # global scope).
    #
    attr_accessor :mutex_name

    #
    # An instance variable for storing the applied workitem if the 'reserve'
    # cannot be entered immediately.
    #
    attr_accessor :applied_workitem


    def apply (workitem)

      return reply_to_parent(workitem) if has_no_expression_child

      @mutex_name = lookup_string_attribute(:mutex, workitem)

      mutex = lookup_variable(@mutex_name) || FlowMutex.new(@mutex_name)

      mutex.register(self, workitem)
    end

    def reply (workitem)

      lookup_variable(@mutex_name).release(self)

      reply_to_parent(workitem)
    end

    #
    # takes care of exiting the critical section once the children
    # have been cancelled
    #
    def cancel

      super

      lookup_variable(@mutex_name).release(self)
    end

    #
    # Called by the FlowMutex to enter the 'reserved/critical' section.
    #
    def enter (workitem=nil)

      apply_child(first_expression_child, workitem || @applied_workitem)
    end
  end

  #
  # A FlowMutex is a process variable (thus serializable) that keeps
  # track of the expressions in a critical section (1!) or waiting for
  # entering it.
  #
  #--
  # The current syncrhonization scheme is 1 thread mutex for all the
  # FlowMutex. Shouldn't be too costly and the operations under sync are
  # quite tiny.
  #++
  #
  class FlowMutex

    #--
    # Granularity level ? "big rock". Only one FlowMutex operation
    # a a time for the whole business process engine...
    #
    #@@class_mutex = Mutex.new
    #++

    attr_accessor :mutex_name
    attr_accessor :feis

    def initialize (mutex_name)

      @mutex_name = mutex_name
      @feis = []
    end

    def register (fexp, workitem)

      @feis << fexp.fei

      fexp.set_variable(@mutex_name, self)

      if @feis.size == 1
        #
        # immediately let the expression enter the critical section
        #
        #fexp.store_itself
        fexp.enter(workitem)
      else
        #
        # later...
        #
        fexp.applied_workitem = workitem
        fexp.store_itself
      end
    end

    def release (releaser)

      next_fei = nil

      current_fei = @feis.delete_at 0

      releaser.set_variable(@mutex_name, self)

      log.warn "release() BAD! c:#{current_fei} r:#{releaser.fei}" \
        if releaser.fei != current_fei

      next_fei = @feis.first

      return unless next_fei

      releaser.get_expression_pool.fetch_expression(next_fei).enter
    end

    #--
    # Used by the ReserveExpression when looking up for a FlowMutex
    # and registering into it.
    #
    #def self.synchronize (&block)
    #  @@class_mutex.synchronize do
    #    block.call
    #  end
    #end
    #++
  end

end

