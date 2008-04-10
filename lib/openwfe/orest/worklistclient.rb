#
#--
# Copyright (c) 2005-2007, John Mettraux, OpenWFE.org
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
# "hecho en Costa Rica"
#

require 'openwfe/workitem'
require 'openwfe/orest/xmlcodec'
require 'openwfe/orest/definitions'
require 'openwfe/orest/restclient'


module OpenWFE

    #
    # Reopening WorkItem to set the MAP_TYPE (as it's used by OpenWFEja...)
    #
    class WorkItem
        def initialize
            @last_modified = nil
            @attributes = {}
            @attributes[MAP_TYPE] = E_SMAP
        end
    end

    #
    # a client to an OpenWFE worklists.
    #
    class WorklistClient < RestClient

        def initialize (url, username, password)
            super
        end

        #
        # Returns the list of stores the worklist hosts
        #
        def list_stores
            r = get('listStores', nil, nil)
            decode(r)
        end

        #
        # An alias for list_stores()
        #
        alias :get_store_names :list_stores

        #
        # Returns the headers of a given store.
        #
        def get_headers (storeName, limit=1000)

            params = {}
            params["limit"] = limit

            decode(get('getHeaders', storeName, params))
        end

        #
        # TODO : rdoc me
        #
        def find_flow_instance (store_name, workflow_instance_id)

            params = {}
            params["id"] = workflow_instance_id

            decode(get('findFlowInstance', store_name, params))
        end

        #
        # Launches a flow (on a given engine and with a given launchitem).
        # The 'engineId' corresponds to an engine's participant name
        # (see etc/engine/participant-map.xml)
        #
        def launch_flow (engineId, launchitem)

            eli = OpenWFE::XmlCodec::encode(launchitem)

            params = {}
            params[ENGINEID] = engineId

            decode(post('launchFlow', nil, params, eli))
        end

        #
        # Returns a workitem (but doesn't put a lock on it, thus modifications
        # to it cannot be communicated with saveWorkitem() or forwardWorkitem()
        # to the worklist)
        #
        def get_workitem (storeName, flowExpressionId)

            get_item('getWorkitem', storeName, flowExpressionId)
        end

        #
        # Returns a workitem and makes sure it's locked in the worklist. Thus,
        # the usage of the methods saveWorkitem() and forwardWorkitem() is
        # possible.
        #
        def get_and_lock_workitem (storeName, flowExpressionId)

            #puts "...getAndLockWorkitem() for #{flowExpressionId}"

            get_item('getAndLockWorkitem', storeName, flowExpressionId)
        end

        #
        # Given a queryMap (a dict of keys and values), locks and returns 
        # the first workitem matching.
        #
        def query_and_lock_workitem (storeName, queryMap)

            hs = get_headers(storeName)
            hs.each do |h|

                #puts "...h.id  #{h.flowExpressionId}"
                #h.attributes.each do |k, v|
                #    puts "......h '#{k}' => '#{v}'"
                #end

                ok = true
                id = nil

                queryMap.each do |key, value|

                    #puts "...'#{key}' => '#{h.attributes[key]}' ?= '#{value}'"
                    ok = (ok and h.attributes[key] == value)
                        #
                        # the parenthesis are very important

                    #puts "  .ok is #{ok}"
                    #puts "  .id is #{h.flowExpressionId}"
                    break unless ok
                end

                #puts "  .id is #{h.flowExpressionId}"

                get_and_lock_workitem(storeName, h.flow_expression_id) if ok
            end

            nil
        end

        #
        # Notifies the worklist that the given workitem has to be unlocked
        # any local (client-side) modification to it are ignored.
        #
        def release_workitem (workitem)

            post_item('releaseWorkitem', workitem)
        end

        #
        # Saves back the workitem in the worklist (and releases it)
        #
        def save_workitem (workitem)

            post_item('saveWorkitem', workitem)
        end

        #
        # Returns the workitem to the worklist so that it can resume 
        # its flow (changes to the workitem are saved).
        #
        def proceed_workitem (workitem)

            post_item('forwardWorkitem', workitem)
        end

        alias :forward_workitem :proceed_workitem

        #
        # Returns the list of flow URLs the user owning this session may
        # launch.
        #
        def list_launchables ()

            params = {}

            decode(get('listLaunchables', nil, params))
        end

        #
        # Delegate the workitem (transfer it to another store).
        #
        def delegate (workitem, targetStoreName)

            ewi = OpenWFE.encode(workitem)

            params = {}
            params[TARGETSTORE] = targetStoreName

            decode(post('delegate', workitem.store, params, ewi))
        end

        #
        # Delegate the workitem (ask the worklist to deliver it to 
        # another participant).
        #
        def delegate_to_participant (workitem, targetParticipantName)

            ewi = OpenWFE.encode(workitem)

            params = {}
            params[TARGETPARTICIPANT] = targetParticipantName

            decode(post('delegate', workitem.store, params, ewi))
        end

        #def queryStore (storeName, query)
        #end

        protected

            def get_item (rest_method_name, store_name, flow_expression_id)

                fei = OpenWFE::XmlCodec::encode flow_expression_id
                fei = OpenWFE::xmldoc_to_string fei, false

                params = {}

                wi = decode(post(rest_method_name, store_name, params, fei))

                wi.store = store_name if wi

                wi
            end

            def post_item (rest_method_name, workitem)

                ewi = OpenWFE::XmlCodec::encode(workitem)

                params = {}

                decode(post(rest_method_name, workitem.store, params, ewi))
            end

    end

end

