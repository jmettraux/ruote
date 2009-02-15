#
#--
# Copyright (c) 2007-2009, John Mettraux, OpenWFE.org
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

require 'yaml'
require 'base64'
require 'thread'

require 'openwfe/service'
require 'openwfe/listeners/listener'

require 'rufus/sqs' # gem 'rufus-sqs'


module OpenWFE
module Extras

  #
  # Polls an Amazon SQS queue for workitems
  #
  # Workitems can be instances of InFlowWorkItem or LaunchItem.
  #
  #   require 'openwfe/extras/listeners/sqslisteners'
  #
  #   ql = OpenWFE::SqsListener("workqueue1", engine.application_context)
  #
  #   engine.add_workitem_listener(ql, "2m30s")
  #     #
  #     # thus, the engine will poll our "workqueue1" SQS queue
  #     # every 2 minutes and 30 seconds
  #
  class SqsListener < Service

    include WorkItemListener
    include Rufus::Schedulable

    #
    # The name of the Amazon SQS whom this listener cares for
    #
    attr_reader :queue_name

    def initialize (service_name, opts)

      @mutex = Mutex.new

      @queue_name = opts[:queue_name] || service_name

      super(service_name, opts)

      linfo { "new() queue is '#{@queue_name}'" }
    end

    #
    # polls the SQS for incoming messages
    #
    def trigger (params)

      @mutex.synchronize do
        # making sure executions do not overlap

        ldebug { "trigger()" }

        qs = Rufus::SQS::QueueService.new

        qs.create_queue(@queue_name)
          # just to be sure it is there

        loop do

          l = qs.get_messages(@queue_name, :timeout => 0, :count => 255)

          break if l.length < 1

          l.each do |msg|

            o = decode_object(msg)

            handle_item(o)

            msg.delete

            ldebug { "trigger() handled successfully msg #{msg.message_id}" }
          end
        end
      end
    end

    #
    # Extracts a workitem from the message's body.
    #
    # By default, this listeners assumes the workitem is stored in
    # its "hash form" (not directly as a Ruby InFlowWorkItem instance).
    #
    # LaunchItem instances (as hash as well) are also accepted.
    #
    def decode_object (message)

      o = Base64.decode64(message.message_body)
      o = YAML.load(o)
      o = OpenWFE::workitem_from_h(o)
      o
    end
  end

end
end

