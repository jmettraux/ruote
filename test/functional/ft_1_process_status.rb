
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Since Sat Jul  7 22:44:00 JST 2007 (tanabata)
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/participants/store_participants'


class FtProcessStatusTest < Test::Unit::TestCase
  include FunctionalBase

  def test_process_status

    #log_level_to_debug

    pdef = OpenWFE.process_definition :name => 'test' do
      store_a
    end

    sa = @engine.register_participant('store_a', OpenWFE::HashParticipant)

    fei = @engine.launch(pdef)

    sa.join # resumes as soon as a workitem reaches the participant

    ps = @engine.process_statuses

    #p ps[fei.wfid].all_expressions.collect { |fexp| fexp.fei.to_s }

    assert_equal 1, ps.size

    assert_equal 1, ps[fei.wfid].expressions.size
    assert_equal 3, ps[fei.wfid].all_expressions.size
    assert_equal 1, ps[fei.wfid].applied_workitems.size
    assert_equal 0, ps[fei.wfid].errors.size

    purge_engine
  end

  def test_ps_with_subprocesses

    pdef = OpenWFE.process_definition :name => 'test' do
      sub0
      process_definition :name => 'sub0' do
        store_a
      end
    end

    sa = @engine.register_participant('store_a', OpenWFE::HashParticipant)

    fei = @engine.launch(pdef)

    sleep 0.350

    ps = @engine.process_status(fei.wfid)

    #ps.all_expressions.each do |fexp|
    #  p [ fexp.class, fexp.fei.expid, fexp.fei.wfid ]
    #end

    assert_equal 0, ps.errors.size
    assert_equal 6, ps.all_expressions.size

    purge_engine
  end
end

