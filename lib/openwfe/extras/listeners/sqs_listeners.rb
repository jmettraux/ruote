#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
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
# Made in Japan.
#++


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

