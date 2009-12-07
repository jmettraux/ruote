
#
# Testing Ruote (OpenWFEru)
#
# Thu Dec  3 22:39:03 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/storage_participant'


class FtStorageParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_participant

    pdef = Ruote.process_definition :name => 'def0' do
      alpha
    end

    @engine.register_participant :alpha, Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(pdef)

    wait_for(:alpha)

    assert_equal 1, @engine.storage.get_many('workitems').size

    alpha = Ruote::StorageParticipant.new
    alpha.context = @engine.context

    wi = alpha.first

    assert_equal Ruote::Workitem, wi.class

    alpha.reply(wi)

    wait_for(wfid)

    assert_nil @engine.process(wfid)
  end
end

