
require 'test/unit'
require 'rubygems'
require 'mocha'

require File.dirname(__FILE__) + '/active_connection'

require 'openwfe/extras/expool/db_errorjournal'


#class ActiveRecord::Base
#  def object_from_yaml (s)
#    return s unless s.is_a?(String) && s =~ /^---/
#    begin
#      YAML::load(s)
#    rescue Exception => e
#      p e
#      return s
#    end
#  end
#end
  #
  # peeking at the deYAMLisation problems


class DbErrorJournalUnitTest < Test::Unit::TestCase

  def setup

    expool = mock
    #expool.expects(:add_observer).once
    expool.expects(:add_observer).at_least(2).at_most(2)

    ac = {}
    ac[:s_expression_pool] = expool

    @journal = OpenWFE::Extras::DbErrorJournal.new(:s_error_journal, ac)
    class << @journal
      public :record_error
      #def do_log (level, msg, &block)
      #  p [ level, msg, block.call ]
      #end
    end
  end

  def teardown
    OpenWFE::Extras::ProcessError.destroy_all
  end

  def test_0

    fei0 = OpenWFE::FlowExpressionId.new_fei(
      :workflow_instance_id => 'wfid0', :expression_id => '0.0')
    fei1 = OpenWFE::FlowExpressionId.new_fei(
      :workflow_instance_id => 'wfid1', :expression_id => '0.0')

    # @fei, @message, @workitem, @error_class, @stacktrace

    @journal.record_error(
      OpenWFE::ProcessError.new(fei0, 'it failed !', nil, nil, nil))

    l = @journal.get_error_log('wfid0')

    assert_equal 1, l.size
    assert_kind_of OpenWFE::ProcessError, l[0]
    assert_equal 'wfid0', l[0].wfid
    #assert_equal 3, l[0].message.size

    @journal.record_error(
      OpenWFE::ProcessError.new(fei0, 'it failed again !', nil, nil, nil))
    @journal.record_error(
      OpenWFE::ProcessError.new(fei1, 'it failed too !', nil, nil, nil))

    l0 = @journal.get_error_log('wfid0')
    l1 = @journal.get_error_log('wfid1')

    assert_equal 2, l0.size
    assert_equal 1, l1.size
    assert_equal 3, OpenWFE::Extras::ProcessError.find_all_by_wfid(['wfid0', 'wfid1']).size

    @journal.remove_error_log('wfid0')

    assert_equal 1, OpenWFE::Extras::ProcessError.count
    assert_equal 1, OpenWFE::Extras::ProcessError.find(:all).size
    assert_equal 1, @journal.get_error_logs.size

    e = OpenWFE::Extras::ProcessError.find(:all)[0]
    assert_not_nil e.created_at
    assert_equal e.created_at.to_i, e.as_owfe_error.date.to_i
  end
end

