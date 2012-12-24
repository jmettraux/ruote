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
  # Reopening the FlowExpression class to add [un]persist methods.
  #
  class FlowExpression

    #--
    # PERSISTENCE
    #++

    # Outputs ids like "0_2!d218c1b", no wfid, only <expid>!<subid>[0, 7]
    #
    def debug_id

      "#{h.fei['expid']}!#{h.fei['subid'][0, 7]}"
    end

    # Persists and fetches the _rev identifier from the storage.
    #
    # Only used by the worker when creating the expression.
    #
    def initial_persist

      r = @context.storage.put(@h, :update_rev => true)

      #t = Thread.current.object_id.to_s[-3..-1]
      #puts "+ per #{debug_id} #{tree[0]} r#{h._rev} t#{t} -> #{r.class}"
      #Ruote.p_caller('+ per')

      raise_or_return('initial_persist failed', r)
    end

    def try_persist

      r = @context.storage.put(@h)

      #t = Thread.current.object_id.to_s[-3..-1]
      #puts "+ per #{debug_id} #{tree[0]} r#{h._rev} t#{t} -> #{r.class}"
      #p self.h.children.collect { |i| Ruote.sid(i) }
      #Ruote.p_caller('+ per')

      r
    end

    def try_unpersist

      r = @context.storage.delete(@h)

      #t = Thread.current.object_id.to_s[-3..-1]
      #puts "- unp #{debug_id} #{tree[0]} r#{h._rev} t#{t} -> #{r.class}"
      #Ruote.p_caller('- unp')

      return r if r

      #if h.has_error
      err = @context.storage.get('errors', "err_#{Ruote.to_storage_id(h.fei)}")
      @context.storage.delete(err) if err
      #end
        # removes any error in the journal for this expression
        # since it will now be gone, no need to keep track of its errors

      nil
    end

    def persist_or_raise

      p_or_raise(true)
    end

    def unpersist_or_raise

      p_or_raise(false)
    end

    alias persist persist_or_raise
    alias unpersist unpersist_or_raise

    # Make sure to persist (retry if necessary).
    #
    def do_persist

      do_p(true)
    end

    # Make sure to unpersist (retry if necessary).
    #
    def do_unpersist

      do_p(false)
    end

    protected

    def raise_or_return(msg, r)

      msg = msg.is_a?(String) ?
        msg : (msg ? 'persist' : 'unpersist') + ' failed'

      raise(
        "#{msg} for " +
        "#{Ruote.to_storage_id(h.fei)} #{tree[0]} #{tree[1].inspect} " +
        'r(' + (r == true ? 'gone' : "rev : #{r['_rev']}") + ')'
      ) if r

      r
    end

    # Does persist or unpersist, returns nothing in particular.
    #
    # Will raise a runtime error if it fails (ie if it happens, there
    # is something wrong with the storage implementation or the engine).
    #
    def p_or_raise(pers)

      r = pers ? try_persist : try_unpersist

      raise_or_return(pers, r)
    end

    # Does persist or unpersist, if successful then returns true. If the
    # expression is gone, returns false.
    # If there is a 'fresher' version of the expression, re-attempt and returns
    # false.
    #
    def do_p(pers)

      case r = pers ? try_persist : try_unpersist
        when true
          false # do not go on
        when Hash
          self.h = r
          self.send("do_#{@msg['action']}", @msg)
          false # do not go on
        else
          true # success, do go on
      end
    end
  end
end

