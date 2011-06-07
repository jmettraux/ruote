
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

    wfid0 = assert_trace('done.', pdef)
    wfid1 = assert_trace("done.\ndone.", pdef)

    sleep 0.100

    assert_equal 21, @engine.storage.get_many('history').size

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

  def test_engine_dot_history

    @engine.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    assert_equal Ruote::StorageHistory, @engine.history.class
  end

  def test_wfids

    @engine.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    @engine.register_participant 'alpha', Ruote::NullParticipant

    3.times do
      @engine.launch(Ruote.define { alpha })
      @engine.wait_for(:alpha)
    end

    assert_equal 3, @engine.history.wfids.size
  end

  # Cf
  #   https://github.com/jmettraux/ruote/issues/29
  #   http://ruote-irclogs.s3.amazonaws.com/log_2011-06-06.html
  #
  def test_concurrence_replies

    @engine.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    pdef = Ruote.define do
      concurrence :count => 1 do
        alpha
        bravo
      end
    end

    @engine.register_participant :alpha, Ruote::NullParticipant
    @engine.register_participant :bravo, Ruote::NoOpParticipant

    #@engine.noisy = true

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    repliers = []

    @engine.context.history.by_wfid(wfid).each do |record|
      if record['action'] == 'reply'
        wi = record['workitem']
        repliers << [ wi['fei']['expid'], wi['participant_name'] ]
      end
    end

    assert_equal [ %w[ 0_0_1 bravo ], %w[ 0_0 bravo ] ], repliers[0, 2]
  end
end

