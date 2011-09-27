
#
# testing ruote
#
# Wed Jul 14 09:43:58 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/participant'


class FtVarParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_var_participant

    pdef = Ruote.process_definition do
      sequence do
        set 'v:alpha' => [ 'Ruote::StorageParticipant', {} ]
        alpha
      end
    end

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:alpha)

    assert_equal 1, @dashboard.storage_participant.size
    assert_equal 'alpha', @dashboard.storage_participant.first.participant_name
  end
end

