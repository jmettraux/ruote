
#
# testing ruote
#
# Tue Jan  5 17:51:10 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/log/storage_history'
require 'ruote/part/no_op_participant'


class FtStorageHistoryTest < Test::Unit::TestCase
  include FunctionalBase

  def test_by_wfid

    pdef = Ruote.process_definition do
      alpha
      echo 'done.'
    end

    history = @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    @dashboard.register_participant :alpha, Ruote::NoOpParticipant

    #noisy

    wfid0 = assert_trace('done.', pdef)
    wfid1 = assert_trace("done.\ndone.", pdef)

    sleep 0.100

    assert_equal 19, @dashboard.storage.get_many('history').size

    h = @dashboard.context.history.by_process(wfid0)
    #h.each { |r| p r }
    assert_equal 9, h.size

    # testing record.to_h

    h = @dashboard.context.history.by_process(wfid1)
    #h.each { |r| p r }
    assert_equal 9, h.size

    history.clear!

    assert_equal 0, @dashboard.storage.get_many('history').size
  end

  def test_by_date

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    6.times do |i|
      @dashboard.storage.put(
        '_id' => "!2010-01-06!11414#{i}!0!!20100106-bichisosupa",
        'type' => 'history')
    end
    7.times do |i|
      @dashboard.storage.put(
        '_id' => "!2010-01-07!11414#{i}!0!!20100107-bichitehoni",
        'type' => 'history')
    end

    assert_equal 6, @dashboard.context.history.by_date('2010-01-06').size
    assert_equal 7, @dashboard.context.history.by_date('2010-01-07').size
  end

  def test_range

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    7.times do |i|
      i = i + 1
      @dashboard.storage.put(
        '_id' => "!2010-01-0#{i}!114147!0!!2010010#{i}-bichisosupo",
        'type' => 'history')
    end

    assert_equal(
      [ Time.parse('2010-01-01 00:00:00 UTC'),
        Time.parse('2010-01-08 00:00:00 UTC') ],
      @dashboard.context.history.range)
  end

  def test_engine_dot_history

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    assert_equal Ruote::StorageHistory, @dashboard.history.class
  end

  def test_wfids

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    @dashboard.register_participant 'alpha', Ruote::NullParticipant

    3.times do
      @dashboard.launch(Ruote.define { alpha })
      @dashboard.wait_for(:alpha)
    end

    assert_equal 3, @dashboard.history.wfids.size
  end

  # Cf
  #   https://github.com/jmettraux/ruote/issues/29
  #   http://ruote-irclogs.s3.amazonaws.com/log_2011-06-06.html
  #
  def test_concurrence_replies

    @dashboard.add_service(
      'history', 'ruote/log/storage_history', 'Ruote::StorageHistory')

    pdef = Ruote.define do
      concurrence :count => 1 do
        alpha
        bravo
      end
    end

    @dashboard.register_participant :alpha, Ruote::NullParticipant
    @dashboard.register_participant :bravo, Ruote::NoOpParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    repliers = []

    @dashboard.context.history.by_wfid(wfid).each do |record|
      if record['action'] == 'reply'
        wi = record['workitem']
        repliers << [ wi['fei']['expid'], wi['participant_name'] ]
      end
    end

    assert_equal [ %w[ 0_0_1 bravo ], %w[ 0_0 bravo ] ], repliers[0, 2]
  end

  class MyStorageHistory < Ruote::StorageHistory

    # Only accept 'dispatched' messages.
    #
    def accept?(msg)

      msg['action'] == 'dispatched'
    end
  end

  def test_accept

    @dashboard.add_service('history', MyStorageHistory)

    @dashboard.register_participant '.+', Ruote::NoOpParticipant

    pdef = Ruote.define do
      alpha
      bravo
      charly
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']

    msgs = @dashboard.history.by_process(wfid)

    assert_equal %w[ dispatched ] * 3, msgs.collect { |m| m['action'] }
  end
end

