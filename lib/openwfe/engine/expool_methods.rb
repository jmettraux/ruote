#
#--
# Copyright (c) 2006-2008, John Mettraux, OpenWFE.org
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
  # ExpressionPool methods available via the engine.
  #
  module ExpoolMethods

    #--
    # METHODS FROM THE EXPRESSION POOL
    #
    # These methods are 'proxy' to method found in the expression pool.
    # They are made available here for a simpler model.
    #++

    #
    # Returns the list of applied expressions belonging to a given
    # workflow instance.
    # May be used to determine where a process instance currently is.
    #
    # This method returns all the expressions (the stack) a process
    # went through to reach its current state.
    #
    # If the unapplied optional parameter is set to true, all the
    # expressions (even those not yet applied) that compose the process
    # instance will be returned.
    #
    def process_stack (workflow_instance_id, unapplied=false)

      get_expression_pool.process_stack workflow_instance_id, unapplied
    end
    alias :get_process_stack :process_stack
    alias :get_flow_stack :process_stack

    #
    # A shortcut for process_stack(wfid, true).representation
    #
    # Returns the representation (tree) for the actual version of the
    # given process instance (returns the tree as running, modifications
    # included).
    #
    def process_representation (workflow_instance_id)

      process_stack(workflow_instance_id, true).representation
    end
    alias :process_tree :process_representation

    #
    # Lists all workflow (process) instances currently in the expool (in
    # the engine).
    # This method will return a list of "process-definition" expressions
    # (i.e. OpenWFE::DefineExpression objects -- each representing the root
    # element of a flow).
    #
    # :wfid ::
    #   will list only one process,
    #   <tt>:wfid => '20071208-gipijiwozo'</tt>
    # :parent_wfid ::
    #   will list only one process, and its subprocesses,
    #   <tt>:parent_wfid => '20071208-gipijiwozo'</tt>
    # :consider_subprocesses ::
    #   if true, "process-definition" expressions
    #   of subprocesses will be returned as well.
    # :wfid_prefix ::
    #   allows your to query for specific workflow instance
    #   id prefixes. for example :
    #   <tt>:wfid_prefix => "200712"</tt>
    #   for the processes started in December.
    # :wfname ::
    #   will return only the process instances who belongs to the given
    #   workflow [name].
    # :wfrevision ::
    #   usued in conjuction with :wfname, returns only the process
    #   instances of a given workflow revision.
    #
    def list_processes (options={})

      get_expression_pool.list_processes options
    end
    alias :list_workflows :list_processes

    #
    # Given any expression of a process, cancels the complete process
    # instance.
    #
    def cancel_process (exp_or_wfid)

      get_expression_pool.cancel_process exp_or_wfid
    end
    alias :cancel_flow :cancel_process
    alias :abort_process :cancel_process

    #
    # Cancels the given expression (and its children if any)
    # (warning : advanced method)
    #
    # Cancelling the root expression of a process is equivalent to
    # cancelling the process.
    #
    def cancel_expression (exp_or_fei)

      get_expression_pool.cancel_expression(exp_or_fei)
    end

    #
    # Forgets the given expression (make it an orphan)
    # (warning : advanced method)
    #
    def forget_expression (exp_or_fei)

      get_expression_pool.forget(exp_or_fei)
    end

    #
    # Pauses a process instance.
    #
    def pause_process (wfid)

      get_expression_pool.pause_process(wfid)
    end

    #
    # Restarts a process : removes its 'paused' flag (variable) and makes
    # sure to 'replay' events (replies) that came for it while it was
    # in pause.
    #
    def resume_process (wfid)

      get_expression_pool.resume_process(wfid)
    end

    #
    # Not a delegate to an expool method, placed here for now.
    #
    # Takes care of removing an error from the error journal and
    # they replays its process at that point.
    #
    def replay_at_error (error)

      get_error_journal.replay_at_error(error)
    end

    protected

      #
      # In case of wfid, returns the root expression of the process,
      # in case of fei, returns the expression itself.
      #
      def fetch_exp (fei_or_wfid)

        exp = if fei_or_wfid.is_a?(String)

          get_expression_pool.fetch_root(fei_or_wfid)

        else

          get_expression_pool.fetch_expression(fei_or_wfid)
        end

        exp or raise "no expression found for '#{fei_or_wfid.to_s}'"
      end
  end
end

