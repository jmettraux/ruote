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

#require 'rubygems'
require 'rufus/sqs' # gem 'rufus-sqs'

require 'openwfe/participants/participant'


module OpenWFE
module Extras

  #
  # This participant dispatches its workitem to an Amazon SQS queue.
  #
  # If the queue doesn't exist, the participant will create it.
  #
  # a small example :
  #
  #   # ...
  #   engine.register_participant(:sqs0, SqsParticipant.new("workqueue0"))
  #   # ...
  #
  # For more details about SQS :
  # http://aws.amazon.com
  #
  class SqsParticipant
    include LocalParticipant

    attr_reader :queue, :queue_service

    #
    # Builds an SqsParticipant instance pointing to a given queue.
    # (Refer to the SQS service on how to set up AWS key ids).
    #
    # By default the host_name is 'queue.amazonaws.com'
    #
    def initialize (queue_name, host_name=nil)

      @queue_name = queue_name

      @queue_service = Rufus::SQS::QueueService.new(host_name)

      @queue_service.create_queue @queue_name
        # make sure the queue exists

      @queue = @queue_service.get_queue @queue_name
    end

    #
    # The method called by the engine when it has a workitem for this
    # participant.
    #
    def consume (workitem)

      msg = encode_workitem(workitem)

      msg_id = @queue_service.put_message(@queue, msg)

      ldebug { "consume() msg sent to queue #{@queue.path} id is #{msg_id}" }
    end

    protected

      #
      # Turns the workitem into a Hash, pass it through YAML and
      # encode64 the result.
      #
      # Override this method as needed.
      #
      # Something of 'text/plain' flavour should be returned.
      #
      def encode_workitem (wi)

        msg = wi.to_h
        msg = YAML.dump(msg)
        msg = Base64.encode64(msg)
        msg
      end
  end

end
end
