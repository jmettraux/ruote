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

require 'base64'
require 'net/http'
require 'rexml/document'

require 'openwfe/version'


module OpenWFE

    #
    # A basic REST client for OpenWFE services (control and worklist)
    #
    class RestClient

        attr_reader \
            :host, :port, :resource, :session_id

        def initialize (url, username, password)

            split_url(url)
            @username = username

            connect(password)
        end

        #
        # Closes this REST client
        #
        def close
            get('endWorkSession', nil, {})
        end

        protected

            def decode (reply)

                raise "Error : #{reply.code} - #{reply.body}" \
                    if reply.code != "200"

                begin
                    xml = REXML::Document.new reply.body
                    OpenWFE::XmlCodec::decode xml.root
                rescue Exception => e
                    if $DEBUG
                        #puts
                        #puts e.to_s
                        puts
                        puts "failed to decode reply :"
                        puts
                        puts reply.body
                        puts
                    end
                    raise e
                end
            end

            #
            # GETs a REST operation
            #
            def get (action, subResourceName, params)

                @httpclient.get(
                    compute_resource(action, subResourceName, params))
            end

            #
            # POSTs a REST operation
            #
            def post (action, subResourceName, params, data)

                @httpclient.post(
                    compute_resource(action, subResourceName, params), 
                    data.to_s)
            end

        private

            def split_url (url)

                @host = nil
                @port = nil
                @resource = nil

                url = url[7..-1] if url[0..6] == 'http://'

                i = url.index('/')
                unless i
                    @resource = '/defaultrestresource'
                else
                    @resource = url[i..-1]
                    url = url[0..i]
                end

                @host, @port = url.split(':')

                if @port == nil
                    @port = 5080
                else
                    @port = Integer(@port[0..-2])
                end
            end

            def connect (password)

                @httpclient = Net::HTTP.new(@host, @port)

                hs = {}
                hs['Authorization'] = \
                    'Basic ' + Base64.encode64(@username+":"+password).strip
                hs['RestClient'] = "openwfe-ruby #{OPENWFERU_VERSION}"
                hs['User-Agent'] = "openwfe-ruby #{OPENWFERU_VERSION}"

                #puts "@resource is '#{@resource}'"
                #puts "hs is '#{hs.inspect}'"

                r = @httpclient.get(@resource, hs)

                #xml = REXML::Document.new(r.body)
                #@session_id = Integer(xml.root.attributes["id"])

                @session_id = decode r
            end

            def compute_resource (action, sub_resource_name, params)

                reso = @resource.dup
                reso += "/#{sub_resource_name}" if sub_resource_name

                reso += "?session=#{@session_id.to_s}&action=#{action}"

                params.each { |k, v| 
                    reso += "&#{k.to_s}=#{v.to_s}" 
                } if params

                reso
            end
    end
end

