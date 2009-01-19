
require 'test/unit'
require 'rubygems'
require 'mocha'

require 'extras/active_connection'
require 'openwfe/extras/expool/db_errorjournal'


class FakeProcessError

  attr_accessor :wfid
  attr_accessor :expid
  attr_accessor :message

  def initialize (wfid, expid, message)

    @wfid = wfid
    @expid = expid
    @message = message
  end
end


class DbErrorJournalUnitTest < Test::Unit::TestCase

  def setup

    expool = mock
    #expool.expects(:add_observer).once
    expool.expects(:add_observer).at_least(2).at_most(2)

    ac = {}
    ac[:s_expression_pool] = expool

    @journal = OpenWFE::Extras::DbErrorJournal.new 'ejournal', ac
    class << @journal
      public :record_error
    end
  end

  def teardown
    OpenWFE::Extras::ProcessError.destroy_all
  end

  def test_0

    @journal.record_error(
      FakeProcessError.new('wfid0', '0.0', [ 'it', 'failed', '!' ]))

    l = @journal.get_error_log 'wfid0'

    assert_equal l.size, 1
    assert_kind_of FakeProcessError, l[0]
    assert_equal l[0].wfid, 'wfid0'
    assert_equal l[0].message.size, 3

    @journal.record_error(
      FakeProcessError.new('wfid0', '0.0', "it failed again"))
    @journal.record_error(
      FakeProcessError.new('wfid1', '0.0', "it failed too"))

    l0 = @journal.get_error_log 'wfid0'
    l1 = @journal.get_error_log 'wfid1'

    assert_equal 2, l0.size
    assert_equal 1, l1.size
    assert_equal 3, OpenWFE::Extras::ProcessError.find_all_by_wfid(['wfid0', 'wfid1']).size

    @journal.remove_error_log 'wfid0'

    assert_equal 1, OpenWFE::Extras::ProcessError.count
    assert_equal 1, OpenWFE::Extras::ProcessError.find(:all).size
    assert_equal 1, @journal.get_error_logs.size
  end
end

