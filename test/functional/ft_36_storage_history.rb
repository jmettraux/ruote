
#
# testing ruote
#
# Tue Jan  5 17:51:10 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/log/fs_history'
require 'ruote/part/no_op_participant'


class FtStorageHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_by_wfid

    pdef = Ruote.process_definition do
      alpha
      echo 'done.'
    end

    history = @engine.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    @engine.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace(pdef, "done.")
    wfid1 = assert_trace(pdef, "done.\ndone.")

    sleep 0.100

    assert_equal 17, @engine.storage.get_many('history').size

    h = @engine.context.history.by_process(wfid0)
    #h.each { |r| p r }
    assert_equal 8, h.size

    # testing record.to_h

    h = @engine.context.history.by_process(wfid1)
    #h.each { |r| p r }
    assert_equal 8, h.size

    history.clear!

    assert_equal 0, @engine.storage.get_many('history').size
  end

  def test_by_date

    flunk
  end
end

