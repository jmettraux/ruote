
#
# testing ruote
#
# Tue Jan  5 17:51:10 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

#require 'ruote/log/fs_history'
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

    wfid0 = assert_trace("done.", pdef)
    wfid1 = assert_trace("done.\ndone.", pdef)

    sleep 0.100

    assert_equal 19, @engine.storage.get_many('history').size

    h = @engine.context.history.by_process(wfid0)
    #h.each { |r| p r }
    assert_equal 9, h.size

    # testing record.to_h

    h = @engine.context.history.by_process(wfid1)
    #h.each { |r| p r }
    assert_equal 9, h.size

    history.clear!

    assert_equal 0, @engine.storage.get_many('history').size
  end

  def test_by_date

    @engine.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    6.times do |i|
      @engine.storage.put(
        '_id' => "!2010-01-06!11414#{i}!0!!20100106-bichisosupo",
        'type' => 'history')
    end
    7.times do |i|
      @engine.storage.put(
        '_id' => "!2010-01-07!11414#{i}!0!!20100107-bichitehoni",
        'type' => 'history')
    end

    assert_equal 6, @engine.context.history.by_date('2010-01-06').size
    assert_equal 7, @engine.context.history.by_date('2010-01-07').size
  end

  def test_range

    @engine.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    7.times do |i|
      i = i + 1
      @engine.storage.put(
        '_id' => "!2010-01-0#{i}!114147!0!!2010010#{i}-bichisosupo",
        'type' => 'history')
    end

    assert_equal(
      [ Time.parse('2010-01-01 00:00:00 UTC'),
        Time.parse('2010-01-08 00:00:00 UTC') ],
      @engine.context.history.range)
  end
end

