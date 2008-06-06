
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'find'
require 'fileutils'

require 'rubygems'

require 'openwfe/def'
require 'openwfe/listeners/listeners'
require 'openwfe/participants/participants'

require 'flowtestbase'


class FlowTest28 < Test::Unit::TestCase
  include FlowTestBase

  #def teardown
  #end

  #def setup
  #end

  #
  # TEST 0

  class TestDefinition0 < OpenWFE::ProcessDefinition
    sequence do
      participant :fp
      _print "done"
    end
  end

  def test_0

    FileUtils.mkdir("./work/in") unless File.exist? "./work/in"

    @engine.register_participant "fp", OpenWFE::FileParticipant
    @engine.add_workitem_listener OpenWFE::FileListener, "500"

    fei = launch TestDefinition0

    sleep 0.350

    Find.find("./work/out/") do |path|
      next unless path.match ".*\.yaml$"
      FileUtils.mv path, "./work/in/"
    end

    sleep 2.000

    assert_equal 1, engine.get_expression_storage.size
  end

end

