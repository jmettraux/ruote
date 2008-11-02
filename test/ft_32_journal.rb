
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#


require 'flowtestbase'

require 'openwfe/def'
require 'openwfe/expool/journal'



class FlowTest32 < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
    #concurrence do
    sequence do
      #set :variable => "//toto", :value => "nada"
      participant :alpha
      bravo
    end
  end

  def test_0

    @engine.application_context[:keep_journals] = true

    @engine.init_service(:s_journal, OpenWFE::Journal)

    @engine.register_participant(:alpha) do |wi|
      @tracer << "alpha\n"
    end
    @engine.register_participant(:bravo) do |wi|
      @tracer << "bravo\n"
    end

    result = dotest(TestDefinition0, "alpha\nbravo")

    journal_service = @engine.get_journal

    fn = journal_service.donedir + "/" + result[2].wfid + ".journal"

    #puts journal_service.analyze(fn)

    assert_equal 1, @engine.get_expression_storage.size

    off = 20

    journal_service.replay(fn, off)
      #
      # replay at offset X without "refiring"
      #
      # flow waits

    sleep 0.350

    #puts @engine.get_expression_storage.to_s
    assert_equal 5, @engine.get_expression_storage.size

    #log_level_to_debug

    journal_service.replay(fn, off, true)
      #
      # replay at offset X with "refiring"
      #
      # flow resumes

    sleep 0.350

    #puts @engine.get_expression_storage.to_s
    assert_equal 1, @engine.get_expression_storage.size
  end

end

