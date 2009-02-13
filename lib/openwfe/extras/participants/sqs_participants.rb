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

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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
