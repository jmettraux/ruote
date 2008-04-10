
#
# testing the sqs with yaml messages
#

require 'test/unit'

require 'yaml'
require 'base64'

require 'openwfe/def'
require 'openwfe/engine/engine'

require 'openwfe/extras/listeners/sqslisteners'
require 'openwfe/extras/participants/sqsparticipants'


class SqsTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    class SqsDefinition0 < OpenWFE::ProcessDefinition
        def make
            participant :sqs
        end
    end

    def test_0

        engine = OpenWFE::Engine.new

        sqsp = OpenWFE::Extras::SqsParticipant.new("wiqueue")
        #class << sqsp
        #    def encode_workitem (wi)
        #        "hello from #{@queue.name}  #{wi.fei.workflow_instance_id}"
        #    end
        #end

        engine.register_participant(:sqs, sqsp)

        engine.add_workitem_listener(
            OpenWFE::Extras::SqsListener.new(
                :wiqueue, engine.application_context), 
            "2s")

        engine.launch(SqsDefinition0)

        sleep(5)

        qs = sqsp.queue_service
        qs.delete_queue("wiqueue")
    end
end
