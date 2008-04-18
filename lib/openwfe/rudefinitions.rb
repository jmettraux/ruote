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

require 'fileutils'

require 'openwfe/utils'
require 'openwfe/version'


module OpenWFE

    #
    # service names

    S_LOGGER = :logger

    S_ENGINE = 'engine'
    S_EXPRESSION_MAP = 'expressionMap'
    S_WFID_GENERATOR = 'wfidGenerator'
    S_WORKQUEUE = 'workQueue'
    S_EXPRESSION_POOL = 'expressionPool'
    S_EXPRESSION_STORAGE = 'expressionStorage'
    S_PARTICIPANT_MAP = 'participantMap'
    S_SCHEDULER = 'scheduler'
    S_ERROR_JOURNAL = 'errorJournal'

    #
    # some special expression names

    EN_ENVIRONMENT = 'environment'

    # 
    # some file storage default values

    DEFAULT_WORK_DIRECTORY = 'work'

    #
    # A mixin for easy OpenWFE service lookup
    # (assumes the presence of an application context instance var)
    #
    module OwfeServiceLocator

        def get_engine
            @application_context[S_ENGINE]
        end
        def get_scheduler
            @application_context[S_SCHEDULER]
        end
        def get_expression_map
            @application_context[S_EXPRESSION_MAP]
        end
        def get_wfid_generator
            @application_context[S_WFID_GENERATOR]
        end
        def get_workqueue
            @application_context[S_WORKQUEUE]
        end
        def get_expool
            @application_context[S_EXPRESSION_POOL]
        end
        def get_expression_pool
            @application_context[S_EXPRESSION_POOL]
        end
        def get_expression_storage
            @application_context[S_EXPRESSION_STORAGE]
        end
        def get_participant_map
            @application_context[S_PARTICIPANT_MAP]
        end
        def get_error_journal
            @application_context[S_ERROR_JOURNAL]
        end

        #
        # Returns the 'journal' service (or nil if there is no
        # journal service available).
        #
        def get_journal
            @application_context['journal']
        end
        
        #
        # Returns all the expression storage in the application context
        # (there is usually a cache and a persisted exp storage).
        #
        def get_expression_storages

            @application_context.inject([]) do |r, (k, v)|
                r << v if OpenWFE::starts_with(k.to_s, S_EXPRESSION_STORAGE)
                r
            end
        end
    end

end

