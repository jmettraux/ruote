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


module Ruote::Exp

  #
  # Reopening the FlowExpression class to add [un]persist methods.
  #
  class FlowExpression

    #--
    # PERSISTENCE
    #++

    # Persists and fetches the _rev identifier from the storage.
    #
    # Only used by the worker when creating the expression.
    #
    def initial_persist

      r = @context.storage.put(@h, :update_rev => true)

      raise(
        "initial_persist failed for " +
        "#{Ruote.to_storage_id(h.fei)} #{tree.first}"
      ) if r != nil

      nil
    end

    def try_persist

      r = @context.storage.put(@h)

      #puts "+ per #{h.fei['expid']} #{tree.first} #{h._rev} --> #{r.class}"
      #Ruote.p_caller('+ per') if r != nil

      r
    end

    def try_unpersist

      r = @context.storage.delete(@h)

      #puts "- unp #{h.fei['expid']} #{tree.first} #{h._rev} --> #{r.class}"
      #Ruote.p_caller('- unp') if r != nil

      return r if r

      if h.has_error

        err = @context.storage.get(
          'errors', "err_#{Ruote.to_storage_id(h.fei)}")

        @context.storage.delete(err) if err
      end

      nil
    end

    #--
    # duplication ahead
    #++

    def persist_or_raise

      r = try_persist

      raise(
        "persist failed for " +
        "#{Ruote.to_storage_id(h.fei)} #{tree.first} #{r.class}"
      ) if r
    end

    def unpersist_or_raise

      r = try_unpersist

      raise(
        "unpersist failed for " +
        "#{Ruote.to_storage_id(h.fei)} #{tree.first} #{r.class}"
      ) if r
    end

    alias :persist :persist_or_raise
    alias :unpersist :unpersist_or_raise

    def do_persist

      do_p(:persist)
    end

    def do_unpersist

      do_p(:unpersist)
    end

    protected

    def do_p (pers)

      case r = self.send("try_#{pers}")
        when true
          (pers == :unpersist)
            # persist FALSE : gone... return false "please don't go on"
            # unpersist TRUE : already gone, should be OK
        when Hash
          self.h = r
          self.send("do_#{@msg['action']}", @msg)
          false
        else
          true
      end
    end
  end
end

