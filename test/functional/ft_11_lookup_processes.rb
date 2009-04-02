
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Tue Mar 31 17:20:55 JST 2009
#

require File.dirname(__FILE__) + '/base'

#require 'openwfe/def'
require 'openwfe/participants/store_participants'


class FtLookupProcesses < Test::Unit::TestCase
  include FunctionalBase


  def test_lookup_processses

    #log_level_to_debug

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        _set :variable => '/toto', :value => '${f:foto}'
        participant :alpha
      end
    end

    sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

    li = OpenWFE::LaunchItem.new(pdef)
    li.foto = 'toto_zero'
    fei0 = @engine.launch(li)

    li = OpenWFE::LaunchItem.new(pdef)
    li.foto = 'toto_one'
    fei1 = @engine.launch(li)

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

    purge_engine
  end

  def test_lookup_processes_with_value_only

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        _set :variable => 'toto', :value => '${f:foto}'
        _set :variable => 'nada', :value => 'nadaval'
        participant :alpha
      end
    end

    sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

    li = OpenWFE::LaunchItem.new(pdef)
    li.foto = 'toto_zero'
    fei0 = @engine.launch(li)

    li = OpenWFE::LaunchItem.new(pdef)
    li.foto = 'toto_one'
    fei1 = @engine.launch(li)

    sleep 0.350

    wfids = @engine.lookup_processes(:value => 'toto_zero')
    assert_equal 1, wfids.size
    wfids = @engine.lookup_processes(:value => 'nadaval')
    assert_equal 2, wfids.size

    # over.

    purge_engine
  end

  def test_lookup_processes_with_nested_fields

    pdef = OpenWFE.process_definition :name => 'test' do
      participant :alpha
    end

    sa = @engine.register_participant :alpha, OpenWFE::HashParticipant

    li = OpenWFE::LaunchItem.new(pdef)
    li.foto = { 'labo' => 'nada' }
    li.me = { 'li' => { 'me' => 'lo' } }
    li.kazoe = 4
    fei0 = @engine.launch(li)

    fei1 = @engine.launch(pdef) # an empty process

    sleep 0.350

    wfids = @engine.lookup_processes(:value => 'lo')
    assert_equal [], wfids

    wfids = @engine.lookup_processes(:value => 'lo', :recursive => true)
    assert_equal [ fei0.wfid ], wfids

    wfids = @engine.lookup_processes(:field => 'foto.labo')
    assert_equal [ fei0.wfid ], wfids

    wfids = @engine.lookup_processes(:f => 'foto.labo', :val => 'other')
    assert_equal [], wfids

    wfids = @engine.lookup_processes(:f => 'foto.labo', :val => 'nada')
    assert_equal [ fei0.wfid ], wfids

    wfids = @engine.lookup_processes(:f => 'me.li.me', :val => 'lo')
    assert_equal [ fei0.wfid ], wfids

    wfids = @engine.lookup_processes(:value => 4)
    assert_equal [ fei0.wfid ], wfids

    wfids = @engine.lookup_processes(:value => '4')
    assert_equal [], wfids

    wfids = @engine.lookup_processes(:value => '4', :to_string => true)
    assert_equal [ fei0.wfid ], wfids

    # over.

    purge_engine
  end

end

