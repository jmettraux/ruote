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


module OpenWFE

    #
    # This mixin gathers all the logic for a threaded expression storage,
    # one that doesn't immediately stores workitems (removes overriding
    # operations).
    # Using this threaded storage brings a very important perf benefit.
    #
    module ThreadedStorageMixin

        #
        # Will take care of stopping the 'queue processing' thread.
        #
        def stop

            @stopped = true
            @queue.push :stop
        end

        #
        # makes sure that the queue isn't actually preparing a batch
        # before returning a result.
        #
        def find_expressions (options)

            Thread.pass

            @mutex.synchronize do
                super
            end
        end

        protected

            #
            # starts the thread that does the actual persistence.
            #
            def start_queue

                @mutex = Mutex.new
                @queue = Queue.new

                Thread.new do

                    loop do

                        events = [ @queue.pop ]

                        @mutex.synchronize do

                            14.times { Thread.pass } # gather some steam

                            @queue.size.times do
                                events << @queue.pop
                            end

                            process_events events
                        end

                        break if events.include?(:stop)
                    end
                end
            end

            #
            # queues an event for later (well within a second) persistence
            #
            def queue (event, fei, fexp=nil)

                if @stopped
                    process_event event, fei, fexp
                else
                    @queue.push [ event, fei, fexp ]
                end
            end

            def process_events (events)

                ldebug { "process_events() #{events.size} events" }

                # reducing the operation count

                events = events.inject({}) do |r, event|
                    r[event[1]] = event if event != :stop
                    r
                end

                ldebug { "process_events() #{events.size} events remaining" }

                # perform the remaining operations

                events.each_value do |event, fei, fexp|

                    process_event event, fei, fexp
                end
            end

            def process_event (event, fei, fexp)

                begin
                    if event == :update
                        self[fei] = fexp
                    else
                        safe_delete fei
                    end
                rescue Exception => e
                    lwarn do
                        "process_event() ':#{event}' exception\n" + 
                        OpenWFE::exception_to_s(e)
                    end
                end
            end

            #
            # a call to delete that tolerates missing .yaml files
            #
            def safe_delete (fei)
                begin
                    self.delete fei
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
