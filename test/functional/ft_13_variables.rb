
#
# Testing Ruote (OpenWFEru)
#
# Tue Jun 23 11:16:39 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtVariablesTest < Test::Unit::TestCase
  include FunctionalBase

  def test_wfid_and_expid

    pdef = Ruote.process_definition do
      echo 'at:${wfid}:${expid}'
    end

    wfid = @engine.launch(pdef)
    wait_for(wfid)

    assert_equal "at:#{wfid}:0_0", @tracer.to_s
  end

  def test_variables_event

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'v', :val => 'x'
        unset :var => 'v'
        echo 'done.'
      end
    end

    #noisy

    assert_trace(pdef, 'done.')

    assert_equal(
      1, logger.log.select { |e| e[0] == :variables && e[1] == :set }.size)
    assert_equal(
      1, logger.log.select { |e| e[0] == :variables && e[1] == :unset }.size)
  end
end

