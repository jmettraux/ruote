
#
# Testing OpenWFEru
#
# John Mettraux at openwfe.org
#

require File.dirname(__FILE__) + '/flowtestbase'
require 'openwfe/def'
require 'openwfe/participants/storeparticipants'


class FlowTest72 < Test::Unit::TestCase
  include FlowTestBase

  #
  # Test 0
  #

  class Test0 < OpenWFE::ProcessDefinition
    sequence do
      _set :variable => "/toto", :value => "${f:foto}"
      participant :alpha
    end
  end

  def test_0

    #log_level_to_debug

    sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

    li = OpenWFE::LaunchItem.new Test0
    li.foto = 'toto_zero'
    fei0 = launch(li)

    li = OpenWFE::LaunchItem.new Test0
    li.foto = 'toto_one'
    fei1 = launch(li)

    sleep 0.350

    # variables...

    wfids = @engine.lookup_processes(:var => 'nada')
    assert_equal 0, wfids.size

    wfids = @engine.lookup_processes(:var => 'toto')
    assert_equal 2, wfids.size
    assert wfids.include?(fei0.wfid)
    assert wfids.include?(fei1.wfid)

    wfids = @engine.lookup_processes(:var => 'toto', :val => 'smurf')
    assert_equal 0, wfids.size

    wfids = @engine.lookup_processes(:var => 'toto', :val => 'toto_.*')
    assert_equal 0, wfids.size

    wfids = @engine.lookup_processes(:var => 'toto', :val => /toto_.*/)
    assert_equal 2, wfids.size

    wfids = @engine.lookup_processes(:var => 'toto', :val => Regexp.compile('toto_one'))
    assert_equal wfids, [ fei1.wfid ]

    # fields...

    wfids = @engine.lookup_processes(:f => 'toto')
    assert_equal 0, wfids.size

    wfids = @engine.lookup_processes(:f => 'foto')
    assert_equal 2, wfids.size

    wfids = @engine.lookup_processes(:f => 'foto', :val => 'toto_zero')
    assert_equal 1, wfids.size

    # field or var...

    wfids = @engine.lookup_processes(:vf => 'foto')
    assert_equal 2, wfids.size

    wfids = @engine.lookup_processes(:vf => 'toto')
    assert_equal 2, wfids.size

    wfids = @engine.lookup_processes(:vf => 'toto', :wfid => fei1.wfid)
    assert_equal 1, wfids.size

    wfids = @engine.lookup_processes(
      :vf => 'toto', :wfid_prefix => fei1.wfid[0, 8])
    assert_equal 2, wfids.size

    # over.

    @engine.cancel_process fei0
    @engine.cancel_process fei1

    sleep 0.350
  end

end

