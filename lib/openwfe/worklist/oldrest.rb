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

require 'openwfe/rexml'
require 'openwfe/orest/xmlcodec'
require 'openwfe/orest/oldrestservlet'


module OpenWFE

  #
  # This webrick servlet provides a REST interface for an old style
  # OpenWFE worklist.
  #
  class OldRestWorklistServlet < OldRestServlet

    def initialize (server, params)
      super
      @worklist = params[:Worklist]
    end

    #
    # The realm for HTTP authentication.
    #
    def get_realm_name
      "worklist"
    end

    #
    # Lists the stores in the worklist
    #
    def do__getstorenames (req, res)

      e = REXML::Element.new 'stores'

      @worklist.each_store do |regex, store_name, store|

        perms = @worklist.get_permissions(
          req.attributes['username'], store_name)

        es = REXML::Element.new 'store'
        es.add_attribute 'name', store_name
        es.add_attribute 'workitem-count', store.size
        es.add_attribute 'permissions', perms
        e << es
      end

      reply_with_xml res, 200, e
    end

    alias :do__liststores :do__getstorenames

    #
    # This implementation simply encodes the workitem, no transformation
    # into headers at all.
    #
    def do__getheaders (req, res)

      limit = req.query['limit']
      limit = limit.to_s.to_i if limit
      limit = nil if limit and limit < 1

      hs = @worklist.get_headers(
        req.attributes['username'],
        get_store_name(req),
        limit)

      # TODO raise "404 no store named '#{store_name}'" unless store
      # TODO raise "403 forbidden"

      e = REXML::Element.new 'headers'

      hs.each do |h|

        workitem, locked = h

        e << OpenWFE::XmlCodec::encode_workitem_as_header(
          workitem, locked)
      end

      reply_with_xml res, 200, e
    end

    #
    # Launches a new process instance.
    #
    def do__launchflow (req, res)

      engine_name = req.query['engineid']
      engine_name = "__nil__" unless engine_name

      launch_item = OpenWFE::XmlCodec::decode req.body

      r = @worklist.launch_flow engine_name, launch_item

      e = REXML::Element.new 'ok'

      e.add_attribute 'flow-id', r.to_s

      reply_with_xml res, 200, e
    end

    #
    # Retrieves a workitem from the worklist
    #
    def do__getworkitem (req, res)

      execute_wi_get :get, req, res
    end

    #
    # Retrieves a workitem from the worklist, locks it and returns it
    #
    def do__getandlockworkitem (req, res)

      execute_wi_get :get_and_lock, req, res
    end

    #
    # Returns the flow expression ids of the workitems with a given
    # workflow instance id in a store.
    #
    def do__findflowinstance (req, res)

      store_name = get_store_name req

      wfid = req.query['id']
      raise "404 'id' not specified" unless wfid

      wis = @worklist.list_workitems(
        req.attributes['username'], store_name, wfid)

      e = REXML::Element.new 'stores'

      wis.each do |wi|
        e << OpenWFE::XmlCodec::encode(wi.fei)
      end

      reply_with_xml res, 200, e
    end

    #
    # Releases a workitem (unlocks it).
    #
    def do__releaseworkitem (req, res)

      execute_wi_post :release, req, res
    end

    #
    # Simply saves the workitem and the modifications done to it.
    #
    def do__saveworkitem (req, res)

      execute_wi_post :save, req, res
    end

    #
    # Forwards the workitem (makes the worklist reply to the engine
    # with the modified workitem)
    #
    def do__forwardworkitem (req, res)

      execute_wi_post :forward, req, res
    end

    protected

      def execute_wi_post (method, req, res)

        store_name = get_store_name req

        wi = OpenWFE::XmlCodec::decode req.body

        @worklist.send(
          method,
          req.attributes['username'],
          store_name,
          wi)
      end

      def execute_wi_get (method, req, res)

        store_name = get_store_name req
        fei = OpenWFE::XmlCodec::decode req.body

        wi = @worklist.send(
          method, req.attributes['username'], store_name, fei)

        raise "404 no workitem found for #{fei.to_s}" unless wi

        reply_with_wi res, wi
      end

      def reply_with_wi (res, wi)

        reply_with_xml res, 200, OpenWFE::XmlCodec::encode(wi)
      end

      def get_store_name (req)

        ss = req.path.split("/")
        raise "404 'store' not specified" if ss.length != 3
        ss[-1]
      end
  end
end

