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

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'thread'
require 'webrick'
require 'rexml/document'
require 'openwfe/orest/xmlcodec'


module OpenWFE

    #
    # A common parent class for the worklist and the engine old-style (2002)
    # REST interface.
    #
    class OldRestServlet < WEBrick::HTTPServlet::AbstractServlet

        MUTEX = Mutex.new
        CT = "Content-Type"

        def initialize (server, params)

            super

            @auth_system = params[:AuthSystem] || {}

            @realm_name = get_realm_name

            @last_given_session_id = -1
            @sessions = {}
        end

        #
        # this default implementation returns "no_realm".
        #
        def get_realm_name
            "no_realm"
        end

        def service req, res

            if req.request_method == 'POST'
                class << req
                    def parse_query
                        @query = WEBrick::HTTPUtils::parse_query(@query_string)
                    end
                end
            end

            username = authenticate req, res

            if req.query_string == nil

                get_new_session username, req, res
                return
            end

            req.attributes['username'] = username

            action = req.query["action"]
            action = action.downcase if action

            if action == "endworksession"
                end_work_session req, res
                return
            end

            action_method = "do__#{action}".intern

            unless self.respond_to?(action_method)
                action_not_implemented action, res
                return
            end

            begin
                self.send action_method, req, res
            rescue Exception => e
                reply_with_exception res, e
            end
        end

        #
        # Returns always the same servlet instance.
        #
        def self.get_instance (server, *options)
            MUTEX.synchronize do
                return @__instance__ if @__instance__
                @__instance__ = self.new(server, *options)
            end
        end

        protected

            def reply_with_error (res, code, error_message)

                res.status = code
                res[CT] = "text/plain"
                res.body = error_message
            end

            def reply_with_exception (res, exception)

                message = exception.message

                ms = message.split

                code = 500
                body = message

                if ms.length > 1 and ms[0].to_i != 0
                    code = Integer(ms[0])
                    body = message[4..-1]
                end

                message << "\n"
                message << OpenWFE::exception_to_s(exception)
                message << "\n"

                reply_with_error(res, code, body)
            end

            def reply_with_xml (res, code, xml)

                res.status = code
                res[CT] = "application/xml"

                if xml.kind_of?(REXML::Element)
                    doc = REXML::Document.new
                    doc << xml
                    xml = OpenWFE::xml_to_s(doc)
                end

                res.body = xml
            end

            def end_work_session (req, res)

                sid = req.query['session']
                @sessions.delete(Integer(sid)) if sid

                @logger.debug "end_work_session() #{sid}"
                #@logger.debug "end_work_session() sessions : #{@sessions.size}"

                reply_with_xml(res, 200, REXML::Element.new('bye'))
            end

            def authenticate req, res

                user = nil

                WEBrick::HTTPAuth::basic_auth(req, res, @realm_name) do |u, p|

                    user = get_session_user req

                    if user
                        true
                    else
                        user = u
                        _authenticate u, p
                    end
                end

                user
            end

            def _authenticate user, pass

                if @auth_system.kind_of?(Hash)
                    @auth_system[user] == pass
                elsif @auth_system.kind_of?(Proc)
                    @auth_system.call user, pass
                elsif @auth_system.respond_to?(:authenticate)
                    @auth_system.authenticate user, pass
                else
                    false
                end
            end

            def determine_agent (req)

                req.addr.join "|"
            end

            def get_new_session username, req, res

                sid = new_session_id

                @sessions[sid] = [ 
                    username,
                    determine_agent(req), 
                    Time.now.to_i 
                ]

                @logger.debug "get_new_session() #{sid}"
                #@logger.debug "get_new_session() sessions : #{@sessions.size}"

                esess = REXML::Element.new 'session'
                esess.add_attribute 'id', sid

                reply_with_xml res, 200, esess
            end
            
            def action_not_implemented action, res

                reply_with_error(
                    res, 404, "action '#{action}' is not implemented.")
            end

            def new_session_id
                MUTEX.synchronize do

                    id = Integer(Time.new.to_f * 100000)

                    id = @last_given_session_id + 1 \
                        if id <= @last_given_session_id

                    @last_given_session_id = id
                    id
                end
            end

            def get_session_user (req)

                sid = req.query['session']

                @logger.debug "get_session_user() sid : #{sid}"

                return nil unless sid

                s = @sessions[Integer(sid)]

                return nil unless s

                username, agent, last_seen = s

                return username if agent == determine_agent(req)

                nil
            end
    end
end

