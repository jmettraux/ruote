
#
# testing ruote
#
# Mon Sep  3 06:29:08 JST 2012
#

require File.expand_path('../base', __FILE__)


class FtPartParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  class MyParticipant < Ruote::Participant
    def on_workitem
      (workitem.fields['seen'] ||= []) << workitem.participant_name
      reply
    end
  end

  def test_participant

    @dashboard.register '.+', MyParticipant

    pdef = Ruote.process_definition do
      alpha
      bravo
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal %w[ alpha bravo ], r['workitem']['fields']['seen']
  end
end

