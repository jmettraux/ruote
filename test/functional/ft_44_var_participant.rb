
#
# testing ruote
#
# Wed Jul 14 09:43:58 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

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

    wfid = @engine.launch(pdef)

    @engine.wait_for(:alpha)

    assert_equal 1, @engine.storage_participant.size
    assert_equal 'alpha', @engine.storage_participant.first.participant_name
  end
end

