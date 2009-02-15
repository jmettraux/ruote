
#
# Testing OpenWFEru (Ruote)
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

require 'openwfe/def'
require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/expool/journal'


class FlowTest32d < Test::Unit::TestCase
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

    fei = launch Test0

    sleep 0.500

    get_journal.flush_buckets

    assert_equal 1, get_error_count(fei.wfid)

    @engine.register_participant(:nada) do |wi|
      @tracer << "nada\n"
    end
    @engine.register_participant(:bravo) do |wi|
      @tracer << "bravo\n"
    end

    assert_equal @tracer.to_s, "alpha"

    get_journal.replay_at_last_error fei.wfid

    sleep 1.0

    assert_equal "alpha\nnada\nbravo", @tracer.to_s

    fn = get_journal.workdir + "/" + fei.wfid + ".journal"
    assert (not File.exist?(fn))
  end

end

