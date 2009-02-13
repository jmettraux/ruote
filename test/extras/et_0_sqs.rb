
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Fri Feb 13 23:11:06 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/extras/participants/sqs_participants'
require 'openwfe/extras/listeners/sqs_listeners'


class EtSqsTest < Test::Unit::TestCase
  include FunctionalBase

  def test_sqs

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        participant :sqs
        _print 'done.'
      end
    end

    sqsp = @engine.register_participant(
      :sqs, OpenWFE::Extras::SqsParticipant.new('wiqueue'))

    @engine.register_listener(
      OpenWFE::Extras::SqsListener, :queue_name => 'wiqueue', :freq => '1s')

    assert_trace(pdef, 'done.')
  end
end

