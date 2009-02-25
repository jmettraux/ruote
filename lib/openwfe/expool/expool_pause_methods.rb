#
#--
# Copyright (c) 2006-2009, John Mettraux OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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

