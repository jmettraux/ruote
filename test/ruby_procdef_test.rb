
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Aug 21 10:22:18 JST 2007
#

require 'rubygems'

require 'test/unit'

require 'find'

require 'openwfe/engine/file_persisted_engine'
require 'openwfe/participants/storeparticipants'


#
# fighting bug at :
# http://rubyforge.org/tracker/index.php?func=detail&aid=13238&group_id=2609&atid=10023
#

class RubyProcDefTest < Test::Unit::TestCase

  def setup

    @engine = OpenWFE::CachedFilePersistedEngine.new(
      :definition_in_launchitem_allowed => true)

    @engine.register_participant :alpha, OpenWFE::HashParticipant
  end

  def teardown

    @engine.stop if @engine
  end

  #
  # TESTS

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      alpha
    end
  end

  def test_0

    fei0 = @engine.launch Test0
    sleep 0.100
    fei1 = @engine.launch Test0
    sleep 0.200

    stack0 = @engine.process_stack fei0.wfid
    stack1 = @engine.process_stack fei1.wfid

    #puts stack0
    assert_equal 4, stack0.size
    assert_equal 4, stack1.size

    assert_equal 4, count_files(fei0.wfid)
    assert_equal 4, count_files(fei1.wfid)

    @engine.cancel_process(fei0.wfid)
    @engine.cancel_process(fei1.wfid)

    sleep 0.350
  end


  TEST1 = """
class Test1 < OpenWFE::ProcessDefinition
  sequence do
    alpha
  end
end
  """

  def test_1

    fei0 = launch TEST1
    sleep 0.100
    fei1 = launch TEST1
    sleep 0.200

    assert_equal(
      OpenWFE::ProcessDefinition::Test1,
      OpenWFE::ProcessDefinition.extract_class(TEST1))

    stack0 = @engine.process_stack fei0.wfid
    stack1 = @engine.process_stack fei1.wfid

    #puts stack0
    #puts stack1
    assert_equal 4, stack0.size
    assert_equal 4, stack1.size

    assert_equal 4, count_files(fei0.wfid)
    assert_equal 4, count_files(fei1.wfid)

    @engine.cancel_process(fei0.wfid)
    @engine.cancel_process(fei1.wfid)

    sleep 0.350
  end

  protected

    def launch (test_string)

      filename = "work/procdef.rb"

      File.open(filename, "w") do |f|
        f.puts test_string
      end
      @engine.launch filename
    end

    def count_files (wfid)

      count = 0

      Find.find("work/expool/") do |path|
        next unless path.match(wfid+"__.*\.yaml")
        count += 1
      end

      count
    end

end
