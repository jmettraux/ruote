
#
# Testing Ruote (OpenWFEru)
#
# Fri May 15 09:51:28 JST 2009
#

require File.dirname(__FILE__) + '/base'

require 'ruote/part/hash_participant'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_process_status

    pdef = Ruote.process_definition do
      participant :ref => 'alpha'
    end

    @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait

    ps = @engine.process_status(wfid)

    assert_equal 'no-name', ps.definition_name
    assert_equal nil, ps.definition_revision

    assert_equal({}, ps.variables)
  end

  def test_process_status_variables

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'toto', :val => 'nada'
        participant :ref => 'alpha'
      end
    end

    @engine.register_participant :alpha, Ruote::HashParticipant

    wfid = @engine.launch(pdef, :workitem => { 'kilroy' => 'was here' })

    wait

    ps = @engine.process_status(wfid)

    assert_equal({ 'toto' => 'nada' }, ps.variables)
  end
end

