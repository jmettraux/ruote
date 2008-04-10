#
#--
# Copyright (c) 2007, John Mettraux, OpenWFE.org
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

#require 'openwfe/flowexpressionid'


module OpenWFE

    #
    # This mixin gathers all the logic for a threaded expression storage,
    # one that doesn't immediately stores workitems (removes overriding
    # operations).
    # Using this threaded storage brings a very important perf benefit.
    #
    module ThreadedStorageMixin

        THREADED_FREQ = "427" # milliseconds
            #
            # the frequency at which the event queue should be processed

        #
        # Will take care of stopping the 'queue processing' thread.
        #
        def stop

            get_scheduler.unschedule(@thread_id) if @thread_id

            process_queue
                #
                # flush every remaining events (especially the :delete ones)
        end

        #
        # calls process_queue() before the call the super class each()
        # method.
        #
        def find_expressions (options)

            process_queue
            super
        end

        protected

            #
            # starts the thread that does the actual persistence.
            #
            def start_processing_thread

                @events = {}
                @op_count = 0

                @thread_id = get_scheduler.schedule_every THREADED_FREQ do
                    process_queue
                end
            end

            #
            # queues an event for later (well within a second) persistence
            #
            def queue (event, fei, fe=nil)
                synchronize do

                    old_size = @events.size
                    @op_count += 1

                    @events[fei] = [ event, fei, fe ]

                    ldebug do 
                        "queue() ops #{@op_count} "+
                        "size #{old_size} -> #{@events.size}"
                    end
                end
            end

            #
            # the actual "do persist" order
            #
            def process_queue

                return unless @events.size > 0
                    #
                    # trying to exit as quickly as possible

                ldebug do 
                    "process_queue() #{@events.size} events #{@op_count} ops"
                end

                synchronize do
                    @events.each_value do |v|
                        event = v[0]
                        begin
                            if event == :update
                                self[v[1]] = v[2]
                            else
                                safe_delete(v[1])
                            end
                        rescue Exception => e
                            lwarn do
                                "process_queue() ':#{event}' exception\n" + 
                                OpenWFE::exception_to_s(e)
                            end
                        end
                    end
                    @op_count = 0
                    @events.clear
                end
            end

            #
            # a call to delete that tolerates missing .yaml files
            #
            def safe_delete (fei)
                begin
                    self.delete(fei)
                rescue Exception => e
                #    lwarn do
                #        "safe_delete() exception\n" + 
                #        OpenWFE::exception_to_s(e)
                #    end
                end
            end

            #
            # Adds the queue() method as an observer to the update and remove
            # events of the expression pool.
            # :update and :remove mean changes to expressions in the persistence
            # that's why they are observed.
            #
            def observe_expool

                get_expression_pool.add_observer(:update) do |event, fei, fe|
                    ldebug { ":update  for #{fei.to_debug_s}" }
                    queue event, fei, fe
                end
                get_expression_pool.add_observer(:remove) do |event, fei|
                    ldebug { ":remove  for #{fei.to_debug_s}" }
                    queue event, fei
                end
            end
    end
end
