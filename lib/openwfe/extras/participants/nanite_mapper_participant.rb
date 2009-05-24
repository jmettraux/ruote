#--
# Copyright (c) 2008-2009, Kenneth Kalmer, opensourcery.co.za
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Africa. Kenneth Kalmer of opensourcery.co.za
#++

require 'openwfe/util/json'
require 'nanite'

module OpenWFE
  module Extras

    #
    # Use nanite to shell out heavy lifting to a cluster of self
    # assembling daemons. Learn more about nanite at
    # http://github.com/ezmobius/nanite
    #
    # This participant implements a nanite mapper (or master) that
    # will pass commands out to nanite agents for processing. This
    # happens in an asynchronous fashion, but blocks the workflow from
    # proceeding until a reply gets returned from a nanite agent.
    #
    # This participant assumes some familiarity with nanite and the
    # availability of a working AMQP broker.
    #
    # Configuration example:
    #
    #   engine.register_participant(
    #     :nanite,
    #     OpenWFE::Extras::NaniteMapperParticipant.new( options )
    #   )
    #
    # The options hash passed to the initializer is used by nanite to
    # connect to the AMQP broker, and needs the following keys:
    #
    #   :host  - AMQP broker host
    #   :user  - AMQP broker username
    #   :pass  - AMQP broker password
    #   :vhost - AMQP broker vhost
    #
    # Once configured it is very simple to action the nanite mapper:
    #
    #   class NanitePowered0 < OpenWFE::ProcessDefinition
    #     sequence do
    #       nanite :resource => '/simple/echo', :payload => 'ruote'
    #     end
    #   end
    #
    # The participant does take all the parameters exposed by the
    # regular nanite mapper. The exceptions are :resource and :payload
    # which gets slotted nicely into all #request calls.
    class NaniteMapperParticipant
      include LocalParticipant

      # All options as taken by Nanite.start_mapper
      def initialize( options = {} )

        options = { :identity => 'ruote' }.merge(options)

        @em_thread = Thread.new do
          EM.run do
            Nanite.start_mapper( options )
          end
        end
      end

      def stop
        AMQP.stop { EM.stop if EM.reactor_running? }
        @em_thread.join
      end

      def consume( workitem )
        ldebug { "consuming workitem" }

        resource = workitem.params.delete('resource')

        if resource.nil?
          lerror { "no resource specified" }
          raise ArgumentError, "Missing resource in params"
        end

        ldebug { "sending workitem to #{resource}" }
        Nanite.request( resource, OpenWFE::Json.encode( workitem.to_h ), workitem.params ) do |res|
          ldebug { "response from nanite: #{res.inspect}" }

          # res = { "nanite-name" => "return value" }
          json = res.values.first

          hash = OpenWFE::Json.decode(json)
          wi = OpenWFE.workitem_from_h( hash )
          reply_to_engine( wi )
        end
      end
    end
  end
end
