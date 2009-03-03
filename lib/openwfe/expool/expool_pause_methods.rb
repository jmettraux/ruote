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
  # Gets included into the ExpressionPool class
  #
  module ExpoolPauseMethods

    #
    # Pauses a process (sets its /__paused__ variable to true).
    #
    def pause_process (wfid)

      wfid = extract_wfid(wfid)

      root_expression = fetch_root(wfid)

      @paused_instances[wfid] = true
      root_expression.set_variable(OpenWFE::VAR_PAUSED, true)

      onotify(:pause, root_expression.fei)
    end

    #
    # Restarts a process : removes its 'paused' flag (variable) and makes
    # sure to 'replay' events (replies) that came for it while it was
    # in pause.
    #
    def resume_process (wfid)

      wfid = extract_wfid wfid

      root_expression = fetch_root(wfid)

      #
      # remove 'paused' flag

      @paused_instances.delete(wfid)
      root_expression.unset_variable(OpenWFE::VAR_PAUSED)

      #
      # notify ...

      onotify(:resume, root_expression.fei)

      #
      # replay
      #
      # select PausedError instances in separate list

      errors = get_error_journal.get_error_log wfid
      error_class = OpenWFE::PausedError.name
      paused_errors = errors.select { |e| e.error_class == error_class }

      return if paused_errors.size < 1

      # replay select PausedError instances

      paused_errors.each { |e| get_error_journal.replay_at_error e }
    end
  end
end

