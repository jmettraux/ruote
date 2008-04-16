#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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

require 'thread'
require 'openwfe/utils'


module OpenWFE

    #
    # This mixin provides a workqueue and a thread for executing tasks
    # pushed onto it. It uses the thread.rb Queue class.
    #
    # It is currently only used by the ExpressionPool (maybe it'll get
    # merged back into it later).
    #
    module WorkqueueMixin

        #
        # Creates and starts the workqueue.
        #
        def start_workqueue

            @workqueue = Queue.new

            @workstopped = false

            OpenWFE::call_in_thread "ruote workqueue", self do
                loop do
                    do_process_workelement @workqueue.pop
                    break if @workstopped and @workqueue.empty?
                end
            end
        end

        #
        # Returns true if there is or there just was activity for the
        # work queue.
        #
        def is_workqueue_busy?
            
            @workqueue.size > 0
        end

        #
        # Returns the current count of jobs on the workqueue
        #
        def workqueue_size

            @workqueue.size
        end

        #
        # Stops the workqueue.
        #
        def stop_workqueue

            @workstopped = true
        end

        #
        # the method called by the mixer to actually queue the work.
        #
        def queue_work (*args)

            if @workqueue_stopped

                do_process_workelement args
                    #
                    # degraded mode : as if there were no workqueue
            else

                @workqueue.push args
                    #
                    # work will be done later (millisec order)
                    # by the work thread
            end
        end

        #--
        # Returns the current workqueue size
        #
        #def workqueue_size
        #    return 0 unless @workqueue
        #    @workqueue.size
        #end
        #++
    end
end

