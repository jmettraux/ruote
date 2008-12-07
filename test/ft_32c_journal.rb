
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require 'openwfe/expool/journal'

require File.dirname(__FILE__) + '/flowtestbase'


class FlowTest32c < Test::Unit::TestCase
  include FlowTestBase
  include JournalTestBase

  #def teardown
  #end

  #def setup
  #end


  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      participant :alpha
      participant :nada
      participant :bravo
    end
  end

  def test_0

    @engine.application_context[:keep_journals] = true

    @engine.init_service :s_journal, OpenWFE::Journal

    @engine.register_participant(:alpha) do |wi|
      @tracer << "alpha\n"
    end

    class << get_journal
      public :flush_buckets
    end

    #fei = dotest(Test0, "alpha", 0.500, true)
    li = OpenWFE::LaunchItem.new Test0
    fei = launch li

    sleep 0.500

    get_journal.flush_buckets

    fn = get_journal.workdir + "/" + fei.wfid + ".journal"

    #require 'pp'; pp get_journal.load_events(fn)[-1]

    error_event = get_journal.load_events(fn)[-1]

    assert_equal error_event[0], :error
    assert_equal error_event[2].wfid, fei.wfid
    assert_equal error_event[3], :apply

    #
    # replaying the error (should occur a second time)

    get_journal.replay_at_error error_event

    sleep 0.500

    assert_equal 2, get_error_count(fei.wfid)

    #
    # fixing the cause of the error and then replaying the error
    # (should not occur)

    @engine.register_participant(:nada) do |wi|
      @tracer << "nada\n"
    end
    @engine.register_participant(:bravo) do |wi|
      @tracer << "bravo\n"
    end

    assert_equal @tracer.to_s, "alpha"

    get_journal.replay_at_error error_event

    sleep 1.0

    assert_equal @tracer.to_s, "alpha\nnada\nbravo"
  end

end

