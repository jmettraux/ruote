
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

  def test_0

    #log_level_to_debug

    pdef = OpenWFE.process_definition :name => 'test' do
      store_a
    end

    sa = @engine.register_participant('store_a', OpenWFE::HashParticipant)

    fei = @engine.launch(pdef)

    sleep 0.350

    ps = @engine.process_statuses

    #p ps[fei.wfid].all_expressions.collect { |fexp| fexp.fei.to_s }

    assert_equal 1, ps.size

    assert_equal 1, ps[fei.wfid].expressions.size
    assert_equal 3, ps[fei.wfid].all_expressions.size
    assert_equal 1, ps[fei.wfid].applied_workitems.size
    assert_equal 0, ps[fei.wfid].errors.size

    purge_engine
  end
end

