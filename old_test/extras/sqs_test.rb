
#
# testing the sqs with yaml messages
#

require 'test/unit'

require 'yaml'
require 'base64'

require 'rubygems'

%w{ lib test }.each do |path|
  path = File.expand_path(File.dirname(__FILE__) + '/../../' + path)
  $:.unshift(path) unless $:.include?(path)
end

require 'openwfe/def'
require 'openwfe/engine/engine'

require 'openwfe/extras/listeners/sqs_listeners'
require 'openwfe/extras/participants/sqs_participants'


class SqsTest < Test::Unit::TestCase

  class SqsDefinition0 < OpenWFE::ProcessDefinition
    participant :sqs
  end

  def test_0

    engine = OpenWFE::Engine.new(:definition_in_launchitem_allowed => true)

    sqsp = OpenWFE::Extras::SqsParticipant.new('wiqueue')
    #class << sqsp
    #  def encode_workitem (wi)
    #    "hello from #{@queue.name}  #{wi.fei.workflow_instance_id}"
    #  end
    #end

    engine.register_participant(:sqs, sqsp)

    engine.add_workitem_listener(
      OpenWFE::Extras::SqsListener.new(
        :wiqueue, engine.application_context),
      '2s')

    engine.launch(SqsDefinition0)

    sleep(5)

    qs = sqsp.queue_service
    qs.delete_queue('wiqueue')
  end
end
