
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Mar  9 20:43:02 JST 2008
#

require 'flowtestbase'

require 'openwfe/def'
require 'openwfe/participants/storeparticipants'
require 'openwfe/storage/yamlcustom'


class FlowTest84b < Test::Unit::TestCase
  include FlowTestBase

  #
  # TEST 0

  class Test0 < OpenWFE::ProcessDefinition
     sub0
     define "sub0" do
       toto
     end
  end

  def test_0

    #log_level_to_debug

    @engine.register_participant :toto, OpenWFE::NullParticipant

    fei = @engine.launch Test0

    sleep 0.350

    ps = @engine.process_stack(fei.wfid)

    #puts ps.collect { |fexp| fexp.fei.to_short_s }.join("\n")
    assert_equal 6, ps.size

    #assert_equal(
    #  ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sub0", {"ref"=>"sub0"}, []], ["define", {}, ["sub0", ["toto", {"ref"=>"toto"}, []]]]]],
    #  ps.representation)

    #assert_equal(
    #  ["process-definition", {"name"=>"Test", "revision"=>"0"}, [["sub0", {"ref"=>"sub0"}, []], ["define", {}, ["sub0", ["toto", {"ref"=>"toto"}, []]]]]],
    #  @engine.process_representation(fei.wfid))

    assert_equal 9, ps.tree.flatten.size
    assert_equal 9, @engine.process_representation(fei.wfid).flatten.size
      # kinky assertions

    #@engine.process_status(fei.wfid).expressions.collect do |fexp|
    #  puts "#{fexp.fei.to_short_s}\n  =p=>#{fexp.parent_id ? fexp.parent_id.to_short_s : ''}"
    #end
    assert_equal 1, @engine.process_status(fei.wfid).branches

    purge_engine
  end

end

