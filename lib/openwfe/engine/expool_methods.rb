#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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
  # ExpressionPool methods available via the engine.
  #
  module ExpoolMethods

    #--
    # METHODS FROM THE EXPRESSION POOL
    #
    # These methods are 'proxy' to method found in the expression pool.
    # They are made available here for a simpler model.
    #++

    # Given any expression of a process, cancels the complete process
    # instance.
    #
    def cancel_process (exp_or_wfid)

      get_expression_pool.cancel_process(exp_or_wfid)
    end
    alias :cancel_flow :cancel_process
    alias :abort_process :cancel_process

    # Cancels the given expression (and its children if any)
    # (warning : advanced method)
    #
    # Cancelling the root expression of a process is equivalent to
    # cancelling the process.
    #
    def cancel_expression (exp_or_fei)

      get_expression_pool.cancel_expression(exp_or_fei)
    end

    # Pauses a process instance.
    #
    def pause_process (wfid)

      get_expression_pool.pause_process(wfid)
    end

    # Restarts a process : removes its 'paused' flag (variable) and makes
    # sure to 'replay' events (replies) that came for it while it was
    # in pause.
    #
    def resume_process (wfid)

      get_expression_pool.resume_process(wfid)
    end

    # Not a delegate to an expool method, placed here for now.
    #
    # Takes care of removing an error from the error journal and
    # they replays its process at that point.
    #
    def replay_at_error (error)

      get_error_journal.replay_at_error(error)
    end

    # Reapplies an expression.
    #
    # This method is mostly concerned with ParticipantExpression instances
    # whose participant has "stalled" (participants whose reply won't come).
    #
    def reapply (exp_or_fei)

      get_expression_pool.reapply(exp_or_fei)
    end

    protected

    # In case of wfid, returns the root expression of the process,
    # in case of fei, returns the expression itself.
    #
    def fetch_exp (fei_or_wfid)

      exp = if fei_or_wfid.is_a?(String)
        get_expression_pool.fetch_root(fei_or_wfid)
      else
        get_expression_pool.fetch_expression(fei_or_wfid)
      end

      exp || raise("no expression found for '#{fei_or_wfid.to_s}'")
    end
  end
end

